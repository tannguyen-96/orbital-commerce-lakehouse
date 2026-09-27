{% set configs = [
    {
        "table_name": "walmart.silver_technical.orders_t", 
        "columns": """o.order_id,
    o.store_id,
    o.order_timestamp,
    o.payment_method,
    o.order_status,
    o.total_amount,
    o.created_timestamp as order_created_timestamp,
    o.updated_timestamp as order_updated_timestamp,
    o.is_active as order_is_active,
    o.processed_at as order_processed_at,
    current_timestamp() as obt_b_processed_at""",
        "alias": "o"
    },
    {
        "table_name": "walmart.silver_technical.customers_t", 
        "columns": """c.customer_id,
    c.first_name as customer_first_name,
    c.last_name as customer_last_name,
    c.email as customer_email,
    c.phone as customer_phone,
    c.city as customer_city,
    c.province as customer_province,
    c.country as customer_country,
    c.created_timestamp as customer_created_timestamp,
    c.updated_timestamp as customer_updated_timestamp,
    c.is_active as customer_is_active,
    c.processed_at as customer_processed_at""",
        "alias": "c",
        "join_condition": "o.customer_id = c.customer_id"
    },
    {
        "table_name": "walmart.silver_technical.order_items_t", 
        "columns": """oi.order_item_id,
    oi.quantity,
    oi.unit_price,
    oi.line_amount,
    oi.created_timestamp as order_item_created_timestamp,
    oi.updated_timestamp as order_item_updated_timestamp,
    oi.is_active as order_item_is_active,
    oi.processed_at as order_item_processed_at""",
        "alias": "oi",
        "join_condition": "o.order_id = oi.order_id"
    },
    {
        "table_name": "walmart.silver_technical.products_t", 
        "columns": """p.product_id,
    p.product_name,
    p.category,
    p.brand,
    p.price,
    p.created_timestamp as product_created_timestamp,
    p.updated_timestamp as product_updated_timestamp,
    p.is_active as product_is_active,
    p.processed_at as product_processed_at""",
        "alias": "p",
        "join_condition": "oi.product_id = p.product_id"
    },
    {
        "table_name": "walmart.silver_technical.stores_t", 
        "columns": """s.store_name,
    s.city as store_city,
    s.province as store_province,
    s.country as store_country,
    s.created_timestamp as store_created_timestamp,
    s.updated_timestamp as store_updated_timestamp,
    s.is_active as store_is_active,
    s.processed_at as store_processed_at""",
        "alias": "s",
        "join_condition": "o.store_id = s.store_id"
    },
    {
        "table_name": "walmart.silver_technical.employees_t", 
        "columns": """e.employee_id,
    e.first_name as employee_first_name,
    e.last_name as employee_last_name,
    e.email as employee_email,
    e.job_title,
    e.salary,
    e.created_timestamp as employee_created_timestamp,
    e.updated_timestamp as employee_updated_timestamp,
    e.is_active as employee_is_active,
    e.processed_at as employee_processed_at""",
        "alias": "e",
        "join_condition": "o.store_id = e.store_id"
    }
] %}

SELECT{% for config in configs %}
    {{ config['columns'] }}{% if not loop.last %},{% endif %}
    {% endfor %}
FROM{% for config in configs %}{% if loop.first %}
    {{ config['table_name'] }} AS {{ config['alias'] }}{% else %}
LEFT JOIN {{ config['table_name'] }} AS {{ config['alias'] }} 
    ON {{ config['join_condition'] }}{% endif %}{% endfor %}