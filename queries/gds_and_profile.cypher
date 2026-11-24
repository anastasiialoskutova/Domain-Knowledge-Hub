// 1. Створення проєкції графа у пам'яті для GDS (товари + користувачі + взаємодії)
CALL gds.graph.project(
  'ecomRecGraph',
  ['User', 'Product', 'Category'],
  {
    PURCHASED: {orientation: 'UNDIRECTED', properties: 'amount'},
    VIEWED: {orientation: 'UNDIRECTED'},
    CO_OCCURS_WITH: {orientation: 'UNDIRECTED'},
    SIMILAR_TO: {orientation: 'UNDIRECTED'}
  }
);

// 2. PageRank: пошук найвпливовіших вузлів та запис властивості pagerank у граф
CALL gds.pageRank.write('ecomRecGraph', {
  maxIterations: 20,
  dampingFactor: 0.85,
  writeProperty: 'pagerank'
})
YIELD nodePropertiesWritten, ranIterations;

// Топ-10 вузлів за PageRank
MATCH (n)
WHERE n.pagerank IS NOT NULL
RETURN labels(n)[0] AS Type, coalesce(n.product_id, n.user_id, n.category_id) AS ID,
       coalesce(n.title, n.email, n.name) AS Name, round(n.pagerank, 4) AS PageRank
ORDER BY PageRank DESC LIMIT 10;

// 3. Louvain: виявлення спільнот та запис властивості community у граф
CALL gds.louvain.write('ecomRecGraph', {
  writeProperty: 'community'
})
YIELD communityCount, modularity;

// Статистика по виявлених спільнотах (>= 3 спільноти)
MATCH (n)
WHERE n.community IS NOT NULL
RETURN n.community AS CommunityID, count(n) AS Size,
       collect(DISTINCT labels(n)[0]) AS LabelsPresent
ORDER BY Size DESC LIMIT 10;

// Очищення проєкції
CALL gds.graph.drop('ecomRecGraph');

// 4. PROFILE ДО оптимізації (пошук за неіндексованою властивістю та фільтрація після розгортання)
PROFILE
MATCH (u:User)-[r:PURCHASED]->(p:Product)
WHERE toLower(u.city) = 'lviv' AND p.price > 500
RETURN u.user_id, p.title, r.amount;

// 5. PROFILE ПІСЛЯ оптимізації (використання індексів user_city_idx та product_price_idx без блокуючої функції toLower)
PROFILE
MATCH (u:User)-[r:PURCHASED]->(p:Product)
WHERE u.city = 'Lviv' AND p.price > 500
RETURN u.user_id, p.title, r.amount;