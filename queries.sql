--1. top_10_total_income

SELECT first_name || ' '|| last_name as seller, -- отчет с продавцами у которых наибольшая выручка. соединяем имя и фамилию в одну колонку
coalesce(FLOOR(SUM(sales.quantity)),0) as operations,--выводим quantity как operations, используем округление, избавивишись от чисел после запятой
coalesce(FLOOR(SUM (products.price*sales.quantity)),0) as income
from employees as employees
left join sales as sales on
employees.employee_id = sales.sales_person_id
left join products as products on
products.product_id = sales.product_id
group by seller
order by income desc
limit 10;

--2. lowest_average_income
WITH seller_stats AS ( --создаем CTE Отчет с продавцами, чья выручка ниже средней выручки всех продавцов
SELECT first_name || ' '|| last_name as seller, --соединяем имя и фамилию в одну колонку
coalesce(FLOOR(SUM(sales.quantity)),0) as operations,
coalesce(FLOOR(AVG (products.price*sales.quantity)),0) as income,-- выводим столбец income как произведение price*quantity
coalesce(FLOOR(SUM (products.price*sales.quantity)),0) - FLOOR(AVG(COALESCE(SUM(products.price * sales.quantity), 0)) OVER()) as average_income
from employees as employees-- с помощью оконной функции рассчитываю среднее занчение по всем продавцам и получаю отклонение по каждому продавцу от общего среднего
join sales as sales on--присоединие таблицы sales
employees.employee_id = sales.sales_person_id
left join products as products on--присоединение таблицы products
products.product_id = sales.product_id
group by seller
)
SELECT 
    seller,
    average_income
FROM seller_stats
where average_income < 0--ывожу список продавцов, у которых доход меньше среденего по всем продавцам
ORDER BY average_income;

--3.day_of_the_week_income
	select first_name || ' '|| last_name as seller,
	lower(trim(to_char (sales.sale_date, 'Day'))) as day_of_week,
	coalesce(FLOOR(SUM(products.price*sales.quantity)),0) as income
	from employees as employees
	left join sales as sales on
	employees.employee_id = sales.sales_person_id
	left join products as products on
	products.product_id = sales.product_id
	GROUP BY 
    first_name || ' ' || last_name,
    to_char(sales.sale_date, 'Day'),
    EXTRACT(ISODOW FROM sales.sale_date)
ORDER BY 
    EXTRACT(ISODOW FROM sales.sale_date),  -- сортировка по порядковому номеру дня недели
    seller;           


--4. age_groups
SELECT 
    age_category,
    COUNT(*) as age_count
FROM (--создаем подзапрос с категориями
    SELECT 
        CASE 
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            WHEN age > 40 THEN '40+'
        END as age_category
    FROM customers
) as categorized
GROUP BY age_category
ORDER BY age_category;

--5.customers_by_month количество покупателей и выручкой по месяцам
SELECT 
    TO_CHAR(sales.sale_date, 'YYYY-MM') as selling_month,
    COUNT(DISTINCT c.customer_id) as total_customers,
    coalesce(FLOOR(SUM (products.price*sales.quantity)),0) as income
FROM sales
LEFT JOIN customers as c ON sales.customer_id = c.customer_id
LEFT JOIN products ON sales.product_id = products.product_id
GROUP BY TO_CHAR(sales.sale_date, 'YYYY-MM')
order by selling_month 

--6. special_offer  покупатели первая покупка которых пришлась на время проведения специальных акций

SELECT 
    c.first_name || ' ' || c.last_name AS customer,
    MIN(first_purchase.first_sale_date) AS sale_date,  -- MIN на случай дублей
    MIN(e.first_name || ' ' || e.last_name) AS seller   -- берем первого продавца
FROM customers c
JOIN (
    SELECT 
        customer_id,
        MIN(sale_date) as first_sale_date
    FROM sales
    GROUP BY customer_id
) first_purchase ON c.customer_id = first_purchase.customer_id
JOIN sales s ON first_purchase.customer_id = s.customer_id 
               AND first_purchase.first_sale_date = s.sale_date
JOIN products p ON s.product_id = p.product_id
JOIN employees e ON s.sales_person_id = e.employee_id
WHERE p.price = 0
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY c.customer_id;

