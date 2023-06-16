/*Growth Rate */
SELECT YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders USING(website_session_id)
GROUP BY 1,2
ORDER BY 1,2;

/*Corporation efficiency */
SELECT YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr,
    COUNT(DISTINCT orders.order_id)/ COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order_conv_rate,
    SUM(orders.price_usd)/COUNT(DISTINCT orders.order_id) AS revenue_per_order,
    SUM(orders.price_usd)/ COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders USING(website_session_id)
GROUP BY 1,2
ORDER BY 1,2;

/*Efficiency from different utm_source and campaign */
SELECT YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS gsearch_nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS bsearch_nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) AS organic_type_in_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) AS direct_type_in_orders
FROM website_sessions
LEFT JOIN orders USING(website_session_id)
GROUP BY 1,2
ORDER BY 1,2;

/* Convertion rate from different sources */
SELECT YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
    /COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_nonbrand_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
    /COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_nonbrand_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END)
    /COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_search_conv_rate,
	COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END)
    /COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END)
    /COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_conv_rate
FROM website_sessions
LEFT JOIN orders USING(website_session_id)
GROUP BY 1,2
ORDER BY 1,2;

/* revenue and profit by products and total revenue + profit accross month*/
SELECT YEAR(created_at) AS yr,
	MONTH(created_at) AS mo,
    SUM(CASE WHEN product_id = 1 THEN price_usd END) AS mrfuzzy_rev,
    SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd END) AS mrfuzzy_marg,
    SUM(CASE WHEN product_id = 2 THEN price_usd END) AS lovebear_rev,
    SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd END) AS lovebear_marg,
    SUM(CASE WHEN product_id = 3 THEN price_usd END) AS birthdaybear_rev,
    SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd END) AS birthdaybear_marg,
    SUM(CASE WHEN product_id = 4 THEN price_usd END) AS minbear_rev,
    SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd END) AS minbear_marg,
    SUM(price_usd) AS total_rev,
    SUM(price_usd - cogs_usd) AS total_margin
FROM order_items
GROUP BY 1,2
ORDER BY 1,2;

/* Impact of new products */
DROP TABLE products_pageview;
CREATE TEMPORARY TABLE products_pageview
SELECT website_session_id, website_pageview_id, created_at
FROM website_pageviews
WHERE pageview_url = '/products';

SELECT YEAR(products_pageview.created_at) AS yr, 
	MONTH(products_pageview.created_at) AS mo,
    COUNT(DISTINCT products_pageview.website_session_id) AS session_to_product_page,
	COUNT(DISTINCT website_pageviews.website_session_id) AS click_to_next,
    COUNT(DISTINCT website_pageviews.website_session_id)/COUNT(DISTINCT products_pageview.website_session_id) AS clickthrough_rt,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/ COUNT(DISTINCT products_pageview.website_session_id) AS product_to_order_rt
FROM products_pageview
LEFT JOIN website_pageviews
	ON products_pageview.website_session_id = website_pageviews.website_session_id
    AND website_pageviews.website_pageview_id > products_pageview.website_pageview_id
LEFT JOIN orders ON orders.website_session_id = products_pageview.website_session_id
GROUP BY 1,2
ORDER BY 1,2;

/* Efficiency of cross-selling products */
SELECT orders.primary_product_id, 
	COUNT(DISTINCT orders.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END) AS _xsold_p1,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END) AS _xsold_p2,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END) AS _xsold_p3,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN orders.order_id ELSE NULL END) AS _xsold_p4,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END)
    /COUNT(DISTINCT orders.order_id) AS p1_xsell_rt,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END)
    /COUNT(DISTINCT orders.order_id) AS p2_xsell_rt,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END)
    /COUNT(DISTINCT orders.order_id) AS p3_xsell_rt,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN orders.order_id ELSE NULL END)
    /COUNT(DISTINCT orders.order_id) AS p4_xsell_rt
FROM orders
LEFT JOIN order_items
	ON orders.order_id = order_items.order_id
    AND order_items.is_primary_item = 0
WHERE orders.created_at > "2014-12-05"
GROUP BY 1;