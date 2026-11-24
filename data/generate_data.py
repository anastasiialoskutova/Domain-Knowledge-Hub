import os
import random
import pandas as pd

random.seed(42)
os.makedirs("data", exist_ok=True)

# 1. Вузли: Segment (4), Category (6), Brand (8), User (35), Product (50), PromoCampaign (5)
# Разом = 108 вузлів (>= 100, критерій R2.C1)

segments = [
    {"segment_id": "SEG_VIP", "name": "VIP High-Spenders", "min_ltv": 1500.0},
    {"segment_id": "SEG_TECH", "name": "Tech Enthusiasts", "min_ltv": 500.0},
    {"segment_id": "SEG_BUDGET", "name": "Budget Hunters", "min_ltv": 50.0},
    {"segment_id": "SEG_NEW", "name": "Newcomers", "min_ltv": 0.0},
]

categories = [
    {"category_id": "CAT_LAP", "name": "Laptops", "tax_rate": 0.20},
    {"category_id": "CAT_PHN", "name": "Smartphones", "tax_rate": 0.20},
    {"category_id": "CAT_ACC", "name": "Accessories", "tax_rate": 0.20},
    {"category_id": "CAT_AUD", "name": "Audio", "tax_rate": 0.20},
    {"category_id": "CAT_SMH", "name": "Smart Home", "tax_rate": 0.20},
    {"category_id": "CAT_FIN", "name": "Fintech Subscriptions", "tax_rate": 0.00},
]

brands = [
    {"brand_id": f"BRD_{i}", "name": name, "country": country}
    for i, (name, country) in enumerate([
        ("Apple", "USA"), ("Samsung", "South Korea"), ("Sony", "Japan"),
        ("Logitech", "Switzerland"), ("Anker", "China"), ("Dell", "USA"),
        ("Bose", "USA"), ("RevolutPay", "UK")
    ], 1)
]

promos = [
    {"promo_id": f"PRM_{i}", "title": title, "discount_pct": disc}
    for i, (title, disc) in enumerate([
        ("Black Friday Cashback", 15), ("Apple Ecosystem Bundle", 10),
        ("First Purchase Bonus", 12), ("Audio Week", 20), ("Fintech Zero Fee", 5)
    ], 1)
]

users = []
for i in range(1, 36):
    seg = random.choice(segments)["segment_id"]
    users.append({
        "user_id": f"USR_{i:03d}",
        "email": f"user{i}@example.com",
        "age": random.randint(19, 55),
        "city": random.choice(["Lviv", "Kyiv", "Kharkiv", "Odesa", "Dnipro"]),
        "ltv": round(random.uniform(100.0, 3500.0), 2),
        "risk_score": round(random.uniform(0.05, 0.85), 2),
        "segment_id": seg
    })

products = []
for i in range(1, 51):
    cat = random.choice(categories)["category_id"]
    brd = random.choice(brands)["brand_id"]
    price = round(random.uniform(25.0, 2200.0), 2)
    products.append({
        "product_id": f"PRD_{i:03d}",
        "sku": f"SKU-2026-{i:04d}",
        "title": f"Product {i} ({cat})",
        "price": price,
        "margin_pct": round(random.uniform(0.08, 0.45), 2),
        "stock": random.randint(0, 120),
        "category_id": cat,
        "brand_id": brd
    })

# 2. Зв'язки (>= 200 зв'язків з властивостями походження source, confidence, validFrom)
rels = []

# User -[BELONGS_TO]-> Segment (35)
for u in users:
    rels.append({
        "src": u["user_id"], "dst": u["segment_id"], "type": "BELONGS_TO",
        "amount": 0.0, "quantity": 0, "source": "RFM_Model_v2",
        "confidence": round(random.uniform(0.80, 0.99), 2), "validFrom": "2026-09-01"
    })

# Product -[IN_CATEGORY]-> Category (50) та -[PRODUCED_BY]-> Brand (50)
for p in products:
    rels.append({
        "src": p["product_id"], "dst": p["category_id"], "type": "IN_CATEGORY",
        "amount": 0.0, "quantity": 0, "source": "PIM_Catalog",
        "confidence": 1.0, "validFrom": "2026-01-15"
    })
    rels.append({
        "src": p["product_id"], "dst": p["brand_id"], "type": "PRODUCED_BY",
        "amount": 0.0, "quantity": 0, "source": "PIM_Catalog",
        "confidence": 1.0, "validFrom": "2026-01-15"
    })

# User -[PURCHASED]-> Product (85)
for _ in range(85):
    u = random.choice(users)
    p = random.choice(products)
    qty = random.randint(1, 3)
    rels.append({
        "src": u["user_id"], "dst": p["product_id"], "type": "PURCHASED",
        "amount": round(p["price"] * qty, 2), "quantity": qty,
        "source": "Payment_Gateway_Logs", "confidence": 1.0,
        "validFrom": f"2026-10-{random.randint(1, 28):02d}"
    })

# User -[VIEWED]-> Product (70)
for _ in range(70):
    u = random.choice(users)
    p = random.choice(products)
    rels.append({
        "src": u["user_id"], "dst": p["product_id"], "type": "VIEWED",
        "amount": 0.0, "quantity": random.randint(1, 10),
        "source": "Clickstream_Kafka", "confidence": 0.95,
        "validFrom": f"2026-11-{random.randint(1, 20):02d}"
    })

# Product -[CO_OCCURS_WITH]-> Product (30)
for _ in range(30):
    p1, p2 = random.sample(products, 2)
    rels.append({
        "src": p1["product_id"], "dst": p2["product_id"], "type": "CO_OCCURS_WITH",
        "amount": 0.0, "quantity": random.randint(5, 50),
        "source": "FP_Growth_Miner", "confidence": round(random.uniform(0.65, 0.94), 2),
        "validFrom": "2026-11-01"
    })

# User -[SIMILAR_TO]-> User (20)
for _ in range(20):
    u1, u2 = random.sample(users, 2)
    rels.append({
        "src": u1["user_id"], "dst": u2["user_id"], "type": "SIMILAR_TO",
        "amount": 0.0, "quantity": 0,
        "source": "Cosine_Embedding_v1", "confidence": round(random.uniform(0.75, 0.96), 2),
        "validFrom": "2026-11-10"
    })

# PromoCampaign -[TARGETS_CATEGORY]-> Category (10)
for prm in promos:
    for cat in random.sample(categories, 2):
        rels.append({
            "src": prm["promo_id"], "dst": cat["category_id"], "type": "TARGETS_CATEGORY",
            "amount": float(prm["discount_pct"]), "quantity": 0,
            "source": "CRM_Campaign_Manager", "confidence": 1.0, "validFrom": "2026-11-01"
        })

pd.DataFrame(segments).to_csv("data/segments.csv", index=False)
pd.DataFrame(categories).to_csv("data/categories.csv", index=False)
pd.DataFrame(brands).to_csv("data/brands.csv", index=False)
pd.DataFrame(promos).to_csv("data/promos.csv", index=False)
pd.DataFrame(users).to_csv("data/users.csv", index=False)
pd.DataFrame(products).to_csv("data/products.csv", index=False)
pd.DataFrame(rels).to_csv("data/relationships.csv", index=False)

print(f"Nodes generated: {len(segments)+len(categories)+len(brands)+len(promos)+len(users)+len(products)}")
print(f"Relationships generated: {len(rels)}")