// Перевірка обмежень та індексів
SHOW CONSTRAINTS;
SHOW INDEXES;

// Підрахунок вузлів та зв'язків
MATCH (n) RETURN labels(n)[0] AS Label, count(n) AS NodeCount;
MATCH ()-[r]->() RETURN type(r) AS RelType, count(r) AS RelCount;

// Тест порушення унікального обмеження (очікується Neo.ClientError.Schema.ConstraintValidationFailed)
CREATE (u:User {user_id: 'USR_001', email: 'duplicate@example.com'});