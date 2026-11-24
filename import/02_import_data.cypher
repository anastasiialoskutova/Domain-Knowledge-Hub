// 1. Імпорт вузлів
LOAD CSV WITH HEADERS FROM 'file:///segments.csv' AS row
MERGE (s:Segment {segment_id: row.segment_id})
SET s.name = row.name, s.min_ltv = toFloat(row.min_ltv);

LOAD CSV WITH HEADERS FROM 'file:///categories.csv' AS row
MERGE (c:Category {category_id: row.category_id})
SET c.name = row.name, c.tax_rate = toFloat(row.tax_rate);

LOAD CSV WITH HEADERS FROM 'file:///brands.csv' AS row
MERGE (b:Brand {brand_id: row.brand_id})
SET b.name = row.name, b.country = row.country;

LOAD CSV WITH HEADERS FROM 'file:///promos.csv' AS row
MERGE (pr:PromoCampaign {promo_id: row.promo_id})
SET pr.title = row.title, pr.discount_pct = toInteger(row.discount_pct);

LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {user_id: row.user_id})
SET u.email = row.email,
    u.age = toInteger(row.age),
    u.city = row.city,
    u.ltv = toFloat(row.ltv),
    u.risk_score = toFloat(row.risk_score);

LOAD CSV WITH HEADERS FROM 'file:///products.csv' AS row
MERGE (p:Product {product_id: row.product_id})
SET p.sku = row.sku,
    p.title = row.title,
    p.price = toFloat(row.price),
    p.margin_pct = toFloat(row.margin_pct),
    p.stock = toInteger(row.stock);

// 2. Імпорт зв'язків з властивостями походження (source, confidence, validFrom)
LOAD CSV WITH HEADERS FROM 'file:///relationships.csv' AS row
WITH row WHERE row.type = 'BELONGS_TO'
MATCH (u:User {user_id: row.src}), (s:Segment {segment_id: row.dst})
MERGE (u)-[r:BELONGS_TO {validFrom: row.validFrom}]->(s)
SET r.source = row.source, r.confidence = toFloat(row.confidence);

LOAD CSV WITH HEADERS FROM 'file:///relationships.csv' AS row
WITH row WHERE row.type = 'IN_CATEGORY'
MATCH (p:Product {product_id: row.src}), (c:Category {category_id: row.dst})
MERGE (p)-[r:IN_CATEGORY {validFrom: row.validFrom}]->(c)
SET r.source = row.source, r.confidence = toFloat(row.confidence);

LOAD CSV WITH HEADERS FROM 'file:///relationships.csv' AS row
WITH row WHERE row.type = 'PRODUCED_BY'
MATCH (p:Product {product_id: row.src}), (b:Brand {brand_id: row.dst})
MERGE (p)-[r:PRODUCED_BY {validFrom: row.validFrom}]->(b)
SET r.source = row.source, r.confidence = toFloat(row.confidence);

LOAD CSV WITH HEADERS FROM 'file:///relationships.csv' AS row
WITH row WHERE row.type = 'PURCHASED'
MATCH (u:User {user_id: row.src}), (p:Product {product_id: row.dst})
MERGE (u)-[r:PURCHASED {validFrom: row.validFrom, amount: toFloat(row.amount)}]->(p)
SET r.quantity = toInteger(row.quantity), r.source = row.source, r.confidence = toFloat(row.confidence);

LOAD CSV WITH HEADERS FROM 'file:///relationships.csv' AS row
WITH row WHERE row.type = 'VIEWED'
MATCH (u:User {user_id: row.src}), (p:Product {product_id: row.dst})
MERGE (u)-[r:VIEWED {validFrom: row.validFrom}]->(p)
SET r.quantity = toInteger(row.quantity), r.source = row.source, r.confidence = toFloat(row.confidence);

LOAD CSV WITH HEADERS FROM 'file:///relationships.csv' AS row
WITH row WHERE row.type = 'CO_OCCURS_WITH'
MATCH (p1:Product {product_id: row.src}), (p2:Product {product_id: row.dst})
MERGE (p1)-[r:CO_OCCURS_WITH {validFrom: row.validFrom}]->(p2)
SET r.quantity = toInteger(row.quantity), r.source = row.source, r.confidence = toFloat(row.confidence);

LOAD CSV WITH HEADERS FROM 'file:///relationships.csv' AS row
WITH row WHERE row.type = 'SIMILAR_TO'
MATCH (u1:User {user_id: row.src}), (u2:User {user_id: row.dst})
MERGE (u1)-[r:SIMILAR_TO {validFrom: row.validFrom}]->(u2)
SET r.source = row.source, r.confidence = toFloat(row.confidence);

LOAD CSV WITH HEADERS FROM 'file:///relationships.csv' AS row
WITH row WHERE row.type = 'TARGETS_CATEGORY'
MATCH (pr:PromoCampaign {promo_id: row.src}), (c:Category {category_id: row.dst})
MERGE (pr)-[r:TARGETS_CATEGORY {validFrom: row.validFrom}]->(c)
SET r.discount_pct = toFloat(row.amount), r.source = row.source, r.confidence = toFloat(row.confidence);