import json
import re
from neo4j import GraphDatabase

ALLOWED_LABELS = {"User", "Product", "Category", "Brand", "Segment", "PromoCampaign"}
ALLOWED_RELS = {
    "BELONGS_TO", "IN_CATEGORY", "PRODUCED_BY", "PURCHASED",
    "VIEWED", "CO_OCCURS_WITH", "SIMILAR_TO", "TARGETS_CATEGORY"
}
FORBIDDEN_KEYWORDS = re.compile(
    r"\b(CREATE|MERGE|DELETE|DETACH|SET|REMOVE|DROP|CALL\s+dbms|LOAD\s+CSV)\b",
    re.IGNORECASE
)

class SafeTextToCypherEvaluator:
    def __init__(self, uri: str, readonly_user: str, readonly_pass: str):
        # Використання облікового запису з роллю READER (read-only)
        self.driver = GraphDatabase.driver(uri, auth=(readonly_user, readonly_pass))

    def validate_and_sanitize(self, cypher: str) -> tuple[bool, str]:
        # 1. Заборона мутацій (Read-only check)
        if FORBIDDEN_KEYWORDS.search(cypher):
            return False, "SECURITY_ERROR: Write/DDL operations are forbidden."

        # 2. Перевірка міток вузлів за схемою
        found_labels = re.findall(r":([A-Z][A-Za-z0-9_]*)", cypher)
        for lbl in found_labels:
            if lbl not in ALLOWED_LABELS and lbl not in ALLOWED_RELS:
                return False, f"SCHEMA_ERROR: Unknown label or relationship '{lbl}'."

        # 3. Примусове додавання LIMIT для захисту від перевантаження пам'яті
        if not re.search(r"\bLIMIT\s+\d+\b", cypher, re.IGNORECASE):
            cypher = cypher.rstrip().rstrip(";") + " LIMIT 25"

        return True, cypher

    def evaluate_dataset(self, jsonl_path: str):
        total, passed = 0, 0
        errors = []

        with open(jsonl_path, "r", encoding="utf-8") as f:
            for line in f:
                item = json.loads(line)
                total += 1
                is_valid, safe_query = self.validate_and_sanitize(item["generated_cypher"])

                if not is_valid:
                    errors.append((item["id"], item["question"], safe_query))
                    continue

                try:
                    with self.driver.session(default_access_mode="READ") as session:
                        res = list(session.run(safe_query))
                        passed += 1
                except Exception as e:
                    errors.append((item["id"], item["question"], f"EXECUTION_ERROR: {e}"))

        accuracy = (passed / total) * 100 if total else 0
        print(f"Text-to-Cypher Accuracy: {passed}/{total} ({accuracy:.1f}%)")
        for err in errors:
            print(f"  [FAIL] {err[0]}: {err[1]} -> {err[2]}")

if __name__ == "__main__":
    # Конфігурація береться зі змінних оточення (без хардкоду паролів у репозиторії)
    import os
    evaluator = SafeTextToCypherEvaluator(
        uri=os.getenv("NEO4J_URI", "bolt://localhost:7687"),
        readonly_user=os.getenv("NEO4J_RO_USER", "reader_user"),
        readonly_pass=os.getenv("NEO4J_RO_PASS", "readonly_pass")
    )
    evaluator.evaluate_dataset("tests/t2c.jsonl")