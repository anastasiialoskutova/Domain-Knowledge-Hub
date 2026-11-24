// CQ1: Колаборативна фільтрація (які товари купували схожі користувачі, але ще не купував цільовий)
MATCH (u:User {user_id: 'USR_001'})-[s:SIMILAR_TO]->(peer:User)-[p:PURCHASED]->(rec:Product)
WHERE NOT (u)-[:PURCHASED]->(rec) AND s.confidence >= 0.75
RETURN rec.product_id AS ProductID, rec.title AS Title, rec.price AS Price,
       round(avg(s.confidence), 3) AS AvgSimilarity, count(peer) AS PeerBuyers
ORDER BY PeerBuyers DESC, AvgSimilarity DESC LIMIT 5;

// CQ2: Топ-5 найприбутковіших категорій товарів за сумарною виручкою та маржею (Агрегації + WITH)
MATCH (u:User)-[r:PURCHASED]->(p:Product)-[:IN_CATEGORY]->(c:Category)
WITH c.name AS Category, sum(r.amount) AS TotalRevenue,
     sum(r.amount * p.margin_pct) AS GrossProfit, count(r) AS Orders
RETURN Category, round(TotalRevenue, 2) AS Revenue, round(GrossProfit, 2) AS Profit, Orders
ORDER BY Profit DESC LIMIT 5;

// CQ3: Пошук найкоротшого шляху довіри/схожості між двома користувачами (shortestPath)
MATCH (u1:User {user_id: 'USR_001'}), (u2:User {user_id: 'USR_015'}),
      path = shortestPath((u1)-[:SIMILAR_TO*..5]-(u2))
RETURN [n IN nodes(path) | n.user_id] AS UserChain, length(path) AS Hops;

// CQ4: Товари, які користувачі переглядали >= 3 разів, але не придбали (OPTIONAL MATCH + Фільтри)
MATCH (u:User)-[v:VIEWED]->(p:Product)
WHERE v.quantity >= 3
OPTIONAL MATCH (u)-[pur:PURCHASED]->(p)
WITH u, p, v, pur
WHERE pur IS NULL
RETURN u.user_id AS UserID, u.ltv AS UserLTV, p.product_id AS ProductID, p.price AS Price, v.quantity AS Views
ORDER BY u.ltv DESC LIMIT 10;

// CQ5: Рекомендація супутніх товарів на основі кошика (шляхи змінної довжини CO_OCCURS_WITH*1..2)
MATCH (u:User {user_id: 'USR_005'})-[:PURCHASED]->(base:Product)-[co:CO_OCCURS_WITH*1..2]->(cross:Product)
WHERE base <> cross AND NOT (u)-[:PURCHASED]->(cross) AND cross.stock > 0
RETURN DISTINCT cross.product_id AS RecommendedSKU, cross.title AS Title,
       cross.price AS Price, length(co) AS StepDistance
ORDER BY StepDistance ASC, cross.price ASC LIMIT 5;

// CQ6: Активні промокампанії для VIP-сегмента з фільтрацією за походженням даних (validFrom, confidence)
MATCH (u:User)-[:BELONGS_TO]->(s:Segment {segment_id: 'SEG_VIP'})
MATCH (u)-[:VIEWED]->(p:Product)-[:IN_CATEGORY]->(c:Category)<-[t:TARGETS_CATEGORY]-(pr:PromoCampaign)
WHERE t.validFrom >= '2026-11-01' AND t.confidence = 1.0
RETURN DISTINCT u.user_id AS VIPUser, pr.title AS Promo, pr.discount_pct AS Discount, c.name AS Category
LIMIT 10;

// CQ7: Аналіз фінансового ризику клієнтів за брендами преміум-сегмента (ціна > 1000)
MATCH (u:User)-[r:PURCHASED]->(p:Product)-[:PRODUCED_BY]->(b:Brand)
WHERE p.price > 1000 AND u.risk_score > 0.5
RETURN b.name AS Brand, count(DISTINCT u) AS HighRiskBuyers,
       round(sum(r.amount), 2) AS AtRiskRevenue, round(avg(u.risk_score), 2) AS AvgRisk
ORDER BY AtRiskRevenue DESC;

// CQ8: Конверсія переглядів у покупки по містах (WITH + умовна агрегація)
MATCH (u:User)
OPTIONAL MATCH (u)-[v:VIEWED]->(:Product)
WITH u.city AS City, count(DISTINCT u) AS Users, count(v) AS TotalViews
MATCH (u2:User {city: City})-[p:PURCHASED]->(:Product)
RETURN City, Users, TotalViews, count(p) AS TotalPurchases,
       round(toFloat(count(p)) / CASE WHEN TotalViews = 0 THEN 1 ELSE TotalViews END, 3) AS ViewToBuyRatio
ORDER BY TotalPurchases DESC;

// CQ9 (Аналіз впливу №1 — глибина >= 3): Каскадний вплив дефіциту товару (stock = 0) на супутні рекомендації та виручку сегментів
MATCH path = (p0:Product)<-[:CO_OCCURS_WITH*1..3]-(p_dep:Product)<-[pur:PURCHASED]-(u:User)-[:BELONGS_TO]->(s:Segment)
WHERE p0.stock < 15
RETURN p0.product_id AS BottleneckProduct, s.name AS AffectedSegment,
       count(DISTINCT p_dep) AS DependentProducts, round(sum(pur.amount), 2) AS ExposedRevenue
ORDER BY ExposedRevenue DESC LIMIT 10;

// CQ10 (Аналіз впливу №2 — глибина >= 3): Поширення промо-знижки через ланцюжок Категорія -> Товар -> Користувач -> Схожі користувачі
MATCH path = (pr:PromoCampaign {promo_id: 'PRM_1'})-[:TARGETS_CATEGORY]->(c:Category)<-[:IN_CATEGORY]-(p:Product)<-[:PURCHASED]-(u:User)-[:SIMILAR_TO*1..2]->(peer:User)
RETURN pr.title AS Campaign, c.name AS Category, count(DISTINCT u) AS DirectBuyers,
       count(DISTINCT peer) AS PotentialReachPeers, round(sum(peer.ltv), 2) AS AddressablePeerLTV;