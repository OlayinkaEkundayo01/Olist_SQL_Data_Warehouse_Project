

/*
==================================================================
Stored Procedure: Load Silver Layer (Bronze ==> Silver)
================================================================
Script Purpose: 
    This stored procedure loads data into the 'silver' schema from bronze layer.

    It performs the following functions:
        - Truncate the silver table before loading data.
        - clean the data, standardized it and load data into silver. 

Parameters:
    None.
   This stored procedure does not accept any parameters or return any values.

Usage example:
    EXEC silver.load_silver -- (To execute the stored procedure)
=================================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '===================================================================';
        PRINT 'Loading Silver Layer';
        PRINT '===================================================================';

        PRINT '-------------------------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-------------------------------------------------------------------';
        -- Loading silver.crm_customers
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: silver.crm_customers';
        TRUNCATE TABLE silver.crm_customers;
        PRINT '>>> Inserting data into silver.crm_customers';
        INSERT INTO silver.crm_customers(
            customer_id,
            customer_unique_id,
            customer_zip_code_prefix,
            customer_city,
            customer_state,
            customer_region_key)

        SELECT
            customer_id,
            customer_unique_id,
            customer_zip_code_prefix,
            STRING_AGG(
                UPPER(LEFT(s.value, 1)) + LOWER(SUBSTRING(s.value, 2, LEN(s.value))),
                ' '
            ) WITHIN GROUP (ORDER BY s.ordinal) AS customer_city,
        CASE UPPER(customer_state) -- Map state code to state name
             WHEN 'AC' THEN 'Acre'
             WHEN 'AM' THEN 'Amazonas'
             WHEN 'AP' THEN 'Amapa'
             WHEN 'PA' THEN 'Para'
             WHEN 'RO' THEN 'Rondonia'
             WHEN 'RR' THEN 'Roraima'
             WHEN 'TO' THEN 'Tocantins'
             WHEN 'AL' THEN 'Alagoas'
             WHEN 'BA' THEN 'Bahia'
             WHEN 'CE' THEN 'Ceara'
             WHEN 'MA' THEN 'Maranhao'
             WHEN 'PB' THEN 'Paraiba'
             WHEN 'PE' THEN 'Pernambuco'
             WHEN 'PI' THEN 'Piaui'
             WHEN 'RN' THEN 'Rio Grande do Norte'
             WHEN 'SE' THEN 'Sergipe'
             WHEN 'DF' THEN 'Distrito Federal (Brasília)'
             WHEN 'GO' THEN 'Goiás'
             WHEN 'MT' THEN 'Mato Grosso'
             WHEN 'MS' THEN 'Mato Grosso do Sul'
             WHEN 'ES' THEN 'Espírito Santo'
             WHEN 'MG' THEN 'Minas Gerais'
             WHEN 'RJ' THEN 'Rio de Janeiro'
             WHEN 'SP' THEN 'Sao Paulo'
             WHEN 'PR' THEN 'Parana'
             WHEN 'RS' THEN 'Rio Grande do Sul' 
             WHEN 'SC' THEN 'Santa Catarina'
        END AS customer_sate,
        CASE                                                   -- Map state code to region
             WHEN UPPER(customer_state) IN ('AC','AM','AP','PA','RO','RR','TO')             THEN 'North'
             WHEN UPPER(customer_state) IN ('AL','BA','CE','MA','PB','PE','PI','RN','SE')   THEN 'Northeast'
             WHEN UPPER(customer_state) IN ('DF','GO','MT','MS')                            THEN 'Central-West'
             WHEN UPPER(customer_state) IN ('ES','MG','RJ','SP')                            THEN 'Southeast'
             WHEN UPPER(customer_state) IN ('PR','RS','SC')                                 THEN 'South'
             ELSE 'n/a'
        END AS customer_region_key
        FROM bronze.crm_customers
        CROSS APPLY STRING_SPLIT(customer_city, ' ', 1) s
        GROUP BY customer_id, customer_unique_id,customer_zip_code_prefix,customer_state;
        SET @end_time = GETDATE()
        PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------------';

         -- Loading silver.crm_geolocation
        SET @start_time = GETDATE();
        PRINT '>> Truncating The Table:  silver.crm_geolocation';
        TRUNCATE TABLE silver.crm_geolocation;
        PRINT '>>> Inserting data into silver.crm_geolocation';
        INSERT INTO silver.crm_geolocation(
            geolocation_zip_code_prefix,
            geolocation_lat,
            geolocation_lng,
            geolocation_city,
            geolocation_state
        )
        SELECT
            g.geolocation_zip_code_prefix,
            g.geolocation_lat,
            g.geolocation_lng,
            STRING_AGG(
                UPPER(LEFT(s.value, 1)) + LOWER(SUBSTRING(s.value, 2, LEN(s.value))),
                ' '
            ) WITHIN GROUP (ORDER BY s.ordinal) AS geolocation_city,
            CASE UPPER(geolocation_state) -- Map state code to state name
             WHEN 'AC' THEN 'Acre'
             WHEN 'AM' THEN 'Amazonas'
             WHEN 'AP' THEN 'Amapa'
             WHEN 'PA' THEN 'Para'
             WHEN 'RO' THEN 'Rondonia'
             WHEN 'RR' THEN 'Roraima'
             WHEN 'TO' THEN 'Tocantins'
             WHEN 'AL' THEN 'Alagoas'
             WHEN 'BA' THEN 'Bahia'
             WHEN 'CE' THEN 'Ceara'
             WHEN 'MA' THEN 'Maranhao'
             WHEN 'PB' THEN 'Paraiba'
             WHEN 'PE' THEN 'Pernambuco'
             WHEN 'PI' THEN 'Piaui'
             WHEN 'RN' THEN 'Rio Grande do Norte'
             WHEN 'SE' THEN 'Sergipe'
             WHEN 'DF' THEN 'Distrito Federal (Brasília)'
             WHEN 'GO' THEN 'Goiás'
             WHEN 'MT' THEN 'Mato Grosso'
             WHEN 'MS' THEN 'Mato Grosso do Sul'
             WHEN 'ES' THEN 'Espírito Santo'
             WHEN 'MG' THEN 'Minas Gerais'
             WHEN 'RJ' THEN 'Rio de Janeiro'
             WHEN 'SP' THEN 'Sao Paulo'
             WHEN 'PR' THEN 'Parana'
             WHEN 'RS' THEN 'Rio Grande do Sul' 
             WHEN 'SC' THEN 'Santa Catarina'
        END AS geolocation_state
        FROM (
            SELECT DISTINCT geolocation_zip_code_prefix, geolocation_lat,
                            geolocation_lng, geolocation_city,geolocation_state
            FROM bronze.crm_geolocation
        ) g
        CROSS APPLY STRING_SPLIT(g.geolocation_city, ' ', 1) s
        GROUP BY g.geolocation_zip_code_prefix, g.geolocation_lat,
                 g.geolocation_lng, g.geolocation_city,geolocation_state;
        SET @end_time = GETDATE()
        PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------------';

         -- Loading silver.crm_order_reviews
        SET @start_time = GETDATE();
        PRINT '>> Truncating The Table:  silver.crm_order_reviews';
        TRUNCATE TABLE silver.crm_order_reviews;
        PRINT '>>> Inserting data into silver.crm_order_reviews';
        INSERT INTO silver.crm_order_reviews(
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
        )
        SELECT
            review_id,
            order_id,
            review_score,
        CASE WHEN review_comment_title IS NULL THEN 'n/a'
             ELSE review_comment_title
        END AS review_comment_title,
        CASE WHEN review_comment_message IS NULL THEN 'n/a'
             ELSE review_comment_message
        END AS review_comment_message,
            review_creation_date,
            review_answer_timestamp
        fROM bronze.crm_order_reviews
        SET @end_time = GETDATE()
        PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------------';

        PRINT '-------------------------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '-------------------------------------------------------------------';

         -- Loading silver.erp_order_items
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: silver.erp_order_items';
        TRUNCATE TABLE silver.erp_order_items;
        PRINT '>>> Inserting data into silver.erp_order_items'
        INSERT INTO silver.erp_order_items(
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
        )
        SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
        FROM bronze.erp_order_items
        SET @end_time = GETDATE()
        PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------------';


         -- Loading silver.erp_order_items
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: silver.erp_order_payments';
        TRUNCATE TABLE silver.erp_order_payments;
        PRINT '>>> Inserting data into silver.erp_order_payments'
        INSERT INTO silver.erp_order_payments (
            order_id,
            payment_sequential,
            payment_type,
            payment_installments,
            payment_value
        )
        SELECT
            b.order_id,
            b.payment_sequential,
            cap.formatted_payment_type AS payment_type,
            b.payment_installments,
            b.payment_value
        FROM 
            bronze.erp_order_payments b
        CROSS APPLY (
            SELECT 
                STRING_AGG(
                    UPPER(LEFT(s.value, 1)) + LOWER(SUBSTRING(s.value, 2, LEN(s.value))), 
                    ' '
                ) AS formatted_payment_type
            FROM 
                STRING_SPLIT(TRIM(b.payment_type), ' ') s
            WHERE 
                s.value <> '' -- Prevents errors if there are double spaces between words
        ) cap;
        SET @end_time = GETDATE()
        PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------------';


        -- Loading silver.erp_orders
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: silver.erp_orders';
        TRUNCATE TABLE silver.erp_orders;
        PRINT '>>> Inserting data into silver.erp_orders'
        INSERT INTO silver.erp_orders (
            order_id,
            customer_id,
            order_status,
            order_purchase_timestamp,
            order_approved_at,
            order_delivered_carrier_date,
            order_delivered_customer_date,
            order_estimated_delivery_date
        )
        SELECT
            b.order_id,
            b.customer_id,
            cap.formatted_order_status AS order_status,
            b.order_purchase_timestamp,
            b.order_approved_at,
            b.order_delivered_carrier_date,
            b.order_delivered_customer_date,
            b.order_estimated_delivery_date
        FROM 
            bronze.erp_orders b
        CROSS APPLY (
            SELECT 
                STRING_AGG(
                    UPPER(LEFT(s.value, 1)) + LOWER(SUBSTRING(s.value, 2, LEN(s.value))), 
                    ' '
                ) AS formatted_order_status
            FROM 
                STRING_SPLIT(b.order_status, ' ') s
        ) cap;
        SET @end_time = GETDATE()
        PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------------';



         -- Loading silver.erp_product_category_name_translation
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: silver.erp_product_category_name_translation';
        TRUNCATE TABLE silver.erp_product_category_name_translation;
        PRINT '>>> Inserting data into silver.erp_product_category_name_translation'
        INSERT INTO silver.erp_product_category_name_translation (
            product_category_name,
            product_category_name_english
        )
        SELECT
            cat.formatted_name AS product_category_name,
            eng.formatted_name_english AS product_category_name_english
        FROM 
            bronze.erp_product_category_name_translation b
        CROSS APPLY (
            SELECT 
                STRING_AGG(
                    UPPER(LEFT(s.value, 1)) + LOWER(SUBSTRING(s.value, 2, LEN(s.value))), 
                    ' '
                ) AS formatted_name
            FROM 
                STRING_SPLIT(b.product_category_name, ' ') s
        ) cat
        CROSS APPLY (
            SELECT 
                STRING_AGG(
                    UPPER(LEFT(s.value, 1)) + LOWER(SUBSTRING(s.value, 2, LEN(s.value))), 
                    ' '
                ) AS formatted_name_english
            FROM 
                STRING_SPLIT(b.product_category_name_english, ' ') s
        ) eng;
        SET @end_time = GETDATE()
        PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------------';

        -- Loading silver.erp_products
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: silver.erp_products';
        TRUNCATE TABLE silver.erp_products;
        PRINT '>>> Inserting data into silver.erp_products'
        INSERT INTO silver.erp_products (
            product_id,
            product_category_name,
            product_name_lenght,
            product_description_lenght,
            product_photos_qty,
            product_weight_g,
            product_length_cm,
            product_height_cm,
            product_width_cm
        )
        SELECT
            b.product_id,
            COALESCE(cat.formatted_category_name, 'n/a') AS product_category_name,
            COALESCE(b.product_name_lenght, 0) AS product_name_lenght,
            COALESCE(b.product_description_lenght, 0) AS product_description_lenght,
            COALESCE(b.product_photos_qty, 0) AS product_photos_qty,
            b.product_weight_g,
            b.product_length_cm,
            b.product_height_cm,
            b.product_width_cm
        FROM 
            bronze.erp_products b
        CROSS APPLY (
            SELECT 
                STRING_AGG(
                    UPPER(LEFT(s.value, 1)) + LOWER(SUBSTRING(s.value, 2, LEN(s.value))), 
                    ' '
                ) AS formatted_category_name
            FROM 
                STRING_SPLIT(b.product_category_name, ' ') s
        ) cat;
        SET @end_time = GETDATE()
        PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------------';

        -- Loading silver.erp_sellers
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: silver.erp_sellers';
        TRUNCATE TABLE silver.erp_sellers;
        PRINT '>>> Inserting data into silver.erp_sellers';
        WITH city_clean AS (
            SELECT
                e.seller_id,
                STRING_AGG(
                    UPPER(LEFT(s.value, 1)) + LOWER(SUBSTRING(s.value, 2, LEN(s.value))),
                    ' '
                ) WITHIN GROUP (ORDER BY s.ordinal) AS seller_city
            FROM bronze.erp_sellers e
            CROSS APPLY STRING_SPLIT(LTRIM(RTRIM(e.seller_city)), ' ', 1) s
            WHERE s.value <> ''
            GROUP BY e.seller_id
        )
        INSERT INTO silver.erp_sellers (
            seller_id,
            seller_zip_code_prefix,
            seller_city,
            seller_state
        )
        SELECT
            e.seller_id,
            e.seller_zip_code_prefix,
            c.seller_city,
            CASE UPPER(TRIM(e.seller_state))
                 WHEN 'AC' THEN 'Acre'
                 WHEN 'AM' THEN 'Amazonas'
                 WHEN 'AP' THEN 'Amapa'
                 WHEN 'PA' THEN 'Para'
                 WHEN 'RO' THEN 'Rondonia'
                 WHEN 'RR' THEN 'Roraima'
                 WHEN 'TO' THEN 'Tocantins'
                 WHEN 'AL' THEN 'Alagoas'
                 WHEN 'BA' THEN 'Bahia'
                 WHEN 'CE' THEN 'Ceara'
                 WHEN 'MA' THEN 'Maranhao'
                 WHEN 'PB' THEN 'Paraiba'
                 WHEN 'PE' THEN 'Pernambuco'
                 WHEN 'PI' THEN 'Piaui'
                 WHEN 'RN' THEN 'Rio Grande do Norte'
                 WHEN 'SE' THEN 'Sergipe'
                 WHEN 'DF' THEN 'Distrito Federal'
                 WHEN 'GO' THEN 'Goias'
                 WHEN 'MT' THEN 'Mato Grosso'
                 WHEN 'MS' THEN 'Mato Grosso do Sul'
                 WHEN 'ES' THEN 'Espirito Santo'
                 WHEN 'MG' THEN 'Minas Gerais'
                 WHEN 'RJ' THEN 'Rio de Janeiro'
                 WHEN 'SP' THEN 'Sao Paulo'
                 WHEN 'PR' THEN 'Parana'
                 WHEN 'RS' THEN 'Rio Grande do Sul'
                 WHEN 'SC' THEN 'Santa Catarina'
                 ELSE 'n/a'
            END
        FROM bronze.erp_sellers e
        LEFT JOIN city_clean c ON e.seller_id = c.seller_id;
        SET @end_time = GETDATE()
        PRINT '>>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds'
        PRINT '>> -------------------'

        SET @batch_end_time = GETDATE();
        PRINT '======================================================================='
        PRINT 'Loading Silver Layer is Completed'
        PRINT ' - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
        PRINT '======================================================================='

    END TRY
    BEGIN CATCH
        PRINT '======================================================================='
        PRINT 'ERROR OCCUR DURING LOADING SILVER LAYER'
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '======================================================================='
    END CATCH
END


