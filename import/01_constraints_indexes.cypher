// Унікальні обмеження (4 обмеження >= 2)
CREATE CONSTRAINT user_id_unique IF NOT EXISTS FOR (u:User) REQUIRE u.user_id IS UNIQUE;
CREATE CONSTRAINT user_email_unique IF NOT EXISTS FOR (u:User) REQUIRE u.email IS UNIQUE;
CREATE CONSTRAINT product_id_unique IF NOT EXISTS FOR (p:Product) REQUIRE p.product_id IS UNIQUE;
CREATE CONSTRAINT product_sku_unique IF NOT EXISTS FOR (p:Product) REQUIRE p.sku IS UNIQUE;
CREATE CONSTRAINT category_id_unique IF NOT EXISTS FOR (c:Category) REQUIRE c.category_id IS UNIQUE;
CREATE CONSTRAINT brand_id_unique IF NOT EXISTS FOR (b:Brand) REQUIRE b.brand_id IS UNIQUE;
CREATE CONSTRAINT segment_id_unique IF NOT EXISTS FOR (s:Segment) REQUIRE s.segment_id IS UNIQUE;
CREATE CONSTRAINT promo_id_unique IF NOT EXISTS FOR (pr:PromoCampaign) REQUIRE pr.promo_id IS UNIQUE;

// Індекси для швидкого пошуку та фільтрації (3 індекси >= 2)
CREATE INDEX user_ltv_idx IF NOT EXISTS FOR (u:User) ON (u.ltv);
CREATE INDEX product_price_idx IF NOT EXISTS FOR (p:Product) ON (p.price);
CREATE INDEX user_city_idx IF NOT EXISTS FOR (u:User) ON (u.city);