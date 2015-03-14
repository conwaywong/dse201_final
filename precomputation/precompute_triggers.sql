-- TRIGGER FOR precomputed table pcategory_state
DROP TRIGGER IF EXISTS t_update_pcategory_state on sales;

CREATE OR REPLACE FUNCTION update_pcategory_state()
  RETURNS trigger AS
$BODY$
BEGIN
	
	UPDATE pcategory_state 
	SET quantity_sold=quantity_sold + NEW.quantity, dollar_value= dollar_value + NEW.price
	WHERE category_id= (
		SELECT c.id
		FROM categories c
		INNER JOIN products p ON c.id=p.cid
		WHERE p.id=NEW.pid
	) AND state_id= (
		SELECT st.id
		FROM users u
		INNER JOIN states st on u.state=st.id
		WHERE u.id=NEW.uid
	);
	
	RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER t_update_pcategory_state AFTER INSERT 
   ON sales FOR EACH ROW
   EXECUTE PROCEDURE public.update_pcategory_state();

-- TRIGGER FOR precomputed table pstate
DROP TRIGGER IF EXISTS t_update_pstate on sales;

CREATE OR REPLACE FUNCTION update_pstate()
  RETURNS trigger AS
$BODY$
BEGIN

	UPDATE pstate 
	SET quantity_sold=quantity_sold + NEW.quantity, dollar_value= dollar_value + NEW.price
	WHERE id= (
		SELECT st.id
		FROM users u
		INNER JOIN states st on u.state=st.id
		WHERE u.id=NEW.uid
	);
	
	RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER t_update_pstate AFTER INSERT 
   ON sales FOR EACH ROW
   EXECUTE PROCEDURE public.update_pstate();

-- TRIGGER FOR precomputed table pcustomer
CREATE OR REPLACE FUNCTION pcustomer_trigger_f() 
	RETURNS TRIGGER AS $BODY$
    BEGIN
		UPDATE 	pcustomer
		SET 	quantity_sold = quantity_sold + NEW.quantity,
				dollar_value = dollar_value + NEW.price
		WHERE 	id = NEW.uid;
		RETURN NULL;
	END;
$BODY$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pcustomer_trigger ON sales;

CREATE TRIGGER pcustomer_trigger
AFTER INSERT ON sales
    FOR EACH ROW EXECUTE PROCEDURE pcustomer_trigger_f();

-- TRIGGER FOR precomputed table pcustomer_product
CREATE OR REPLACE FUNCTION pcustomer_product_trigger_f() 
	RETURNS TRIGGER AS $BODY$
	DECLARE
		m_customer_id	integer;
		m_customer_name	text;
		m_product_id	integer;
		m_product_name	text;
    BEGIN
    
		-- Insert or update the summary row with the new values.
		SELECT c.id, c.name INTO m_category_id, m_category_name
		FROM categories c
		INNER JOIN products p ON c.id=p.cid
		WHERE p.id=NEW.pid;
    
		UPDATE 	pcustomer_product
		SET 	quantity_sold = quantity_sold + NEW.quantity,
				dollar_value = dollar_value + NEW.price
		WHERE 	customer_id = NEW.uid AND
				product_id = NEW.pid;
		IF NOT FOUND THEN
			INSERT INTO pcustomer_product(customer_id, customer_name, product_id, product_name, quantity_sold, dollar_value)
			VALUES (m_customer_id, m_customer_name, m_product_id, m_product_name, NEW.quantity, NEW.price)
		END IF;
		RETURN NULL;
	END;
$BODY$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pcustomer_product_trigger ON sales;

CREATE TRIGGER pcustomer_product_trigger
AFTER INSERT ON sales
    FOR EACH ROW EXECUTE PROCEDURE pcustomer_product_trigger_f();
    
-- TRIGGER FOR precomputed table pcategory
CREATE OR REPLACE FUNCTION pcategory_trigger_f() 
	RETURNS TRIGGER AS $BODY$
	DECLARE
		m_category_id	integer;
		m_category_name	text;
	BEGIN
		-- Insert or update the summary row with the new values.
		SELECT c.id, c.name INTO m_category_id, m_category_name
		FROM categories c
		INNER JOIN products p ON c.id=p.cid
		WHERE p.id=NEW.pid;
		
		UPDATE 	pcategory
		SET 	quantity_sold = quantity_sold + NEW.quantity,
				dollar_value = dollar_value + NEW.price
		WHERE id = m_category_id;
		
		IF NOT found THEN
			INSERT INTO pcategory (id, category_name, quantity_sold, dollar_value)
			VALUES (m_category_id, m_category_name, NEW.quantity, NEW.price);
		END IF;
		RETURN NULL;
	END;
$BODY$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pcategory_trigger ON sales;

CREATE TRIGGER pcategory_trigger
AFTER INSERT ON sales
    FOR EACH ROW EXECUTE PROCEDURE pcategory_trigger_f();
