DROP TABLE IF EXISTS price_history;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;

CREATE TABLE categories (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE products (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(200) NOT NULL,
    price       NUMERIC(10,2) NOT NULL,
    stock       INT NOT NULL DEFAULT 0,
    category_id INT NOT NULL REFERENCES categories(id)
);

CREATE TABLE price_history (
    id         SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    old_price  NUMERIC(10,2) NOT NULL,
    new_price  NUMERIC(10,2) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

--Збережена функція, яка оновлює ціну товару за його ID
CREATE OR REPLACE FUNCTION update_product_price(
    p_product_id INT,
    p_new_price NUMERIC(10,2)
)
RETURNS VOID AS $$
BEGIN
    UPDATE products
    SET price = p_new_price
    WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql;

--Функція, що заповнює таблицю price_history (застосовується тригером)
CREATE OR REPLACE FUNCTION log_price_change() RETURNS trigger AS $$
BEGIN
    INSERT INTO price_history (product_id, old_price, new_price)
    VALUES (OLD.id, OLD.price, NEW.price);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Тригер, який при зміні ціни товару застосовує log_price_change()
CREATE TRIGGER trg_products_price_log
    AFTER UPDATE OF price ON products
    FOR EACH ROW
    WHEN (OLD.price IS DISTINCT FROM NEW.price)
    EXECUTE FUNCTION log_price_change();

INSERT INTO categories (name) VALUES ('Смартфони'), ('Ноутбуки'), ('Навушники'), ('Аксесуари');

INSERT INTO products (name, price, stock, category_id) VALUES
 ('Смартфон 1', 15000.00, 15, 1),
 ('Смартфон 2', 25000.00, 8, 1),
 ('Ноутбук 1', 35000.00, 6, 2),
 ('Ноутбук 2', 28000.00, 13, 2),
 ('Ноутбук 3', 54000.00, 10, 2),
 ('Ноутбук 4', 42000.00, 12, 2),
 ('Навушники 1', 2500.00, 9, 3),
 ('Навушники 2', 3400.00, 12, 3),
 ('Кабель USB-C', 250.00, 40, 4),
 ('Павербанк 1', 500.00, 6, 4),
 ('Павербанк 2', 500.00, 0, 4);