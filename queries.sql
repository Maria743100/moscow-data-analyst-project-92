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

--3day_of_the_week_income
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








    