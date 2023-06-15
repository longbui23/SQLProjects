/*Web that has the most view*/
SELECT pageview_url,
	COUNT(DISTINCT website_pageview_id) AS pvs
FROM website_pageviews
WHERE created_at < "2012-06-09"
GROUP BY 1
ORDER BY COUNT(DISTINCT website_pageview_id) DESC;


/*Find THE web that has the most first entry*/
CREATE TEMPORARY TABLE first_pv_per_session
SELECT website_session_id,
	MIN(website_pageview_id) as first_pv
FROM website_pageviews
WHERE created_at < "2012-06-12"
GROUP BY 1;

SELECT website_pageviews.pageview_url AS landing_page_url,
	COUNT(DISTINCT first_pv_per_session.website_session_id) AS sessions_hitting_page
FROM website_pageviews
LEFT JOIN first_pv_per_session ON website_pageviews.website_pageview_id = first_pv_per_session.first_pv
GROUP BY website_pageviews.pageview_url
ORDER BY COUNT(DISTINCT first_pv_per_session.website_session_id) DESC
LIMIT 1;


/*Finding the bouncing rate of /home */
CREATE TEMPORARY TABLE first_pageviews
SELECT website_session_id,
	MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
WHERE created_at < "2012-06-14"
GROUP BY website_session_id;

CREATE TEMPORARY TABLE session_w_home_landing_page
SELECT first_pageviews.website_session_id,
website_pageviews.pageview_url as landing_page
FROM first_pageviews
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id = first_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url = "/home";

CREATE TEMPORARY TABLE bounced_sessions
SELECT session_w_home_landing_page.website_session_id,
	session_w_home_landing_page.landing_page,
	COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM session_w_home_landing_page
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = session_w_home_landing_page.website_session_id
GROUP BY
	session_w_home_landing_page.website_session_id,
	session_w_home_landing_page.landing_page
HAVING COUNT(website_pageviews.website_pageview_id) = 1;

SELECT 
	COUNT( DISTINCT session_w_home_landing_page.website_session_id) AS sessions,
	COUNT(DISTINCT bounced_sessions.website_session_id) AS bounced_website_session_id,
    COUNT(DISTINCT bounced_sessions.website_session_id)/ COUNT( DISTINCT session_w_home_landing_page.website_session_id) AS bounced_rate
FROM session_w_home_landing_page
LEFT JOIN bounced_sessions
ON session_w_home_landing_page.website_session_id = bounced_sessions.website_session_id
ORDER BY session_w_home_landing_page.website_session_id;

/* A/B Testing For Lander-1 new landing page the dividing 50/50 acquistion rate with /home */
SELECT MIN(created_at) AS first_created_at,
	MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/lander-1' AND created_at IS NOT NULL;

CREATE TEMPORARY TABLE first_test_pageviews
SELECT website_pageviews.website_session_id,
	MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM website_pageviews
INNER JOIN website_sessions
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at < "2012-07-28"
AND website_pageviews.website_pageview_id > 23504
AND utm_source = 'gsearch'
AND utm_campaign = 'nonbrand'
GROUP BY website_pageviews.website_session_id;

CREATE TEMPORARY TABLE nonbrand_test_session_w_landing_page
SELECT first_test_pageviews.website_session_id,
	website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url IN ('/home', '/lander-1');

CREATE TEMPORARY TABLE nonbrand_test_bounced_session
SELECT  nonbrand_test_session_w_landing_page.website_session_id,
	 nonbrand_test_session_w_landing_page.landing_page,
    COUNT(website_pageviews.website_pageview_id) AS counts_of_page_view
FROM  nonbrand_test_session_w_landing_page
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id =  nonbrand_test_session_w_landing_page.website_session_id
GROUP BY nonbrand_test_session_w_landing_page.website_session_id,
nonbrand_test_session_w_landing_page.landing_page
HAVING COUNT(website_pageviews.website_pageview_id) = 1;

SELECT  nonbrand_test_session_w_landing_page.landing_page,
	COUNT(DISTINCT nonbrand_test_session_w_landing_page.website_session_id) AS sessions,
	COUNT(DISTINCT nonbrand_test_bounced_session.website_session_id) AS bounced_session,
    COUNT(DISTINCT nonbrand_test_session_w_landing_page.website_session_id)/ COUNT(DISTINCT nonbrand_test_bounced_session.website_session_id) AS bonce_rate
FROM nonbrand_test_session_w_landing_page
LEFT JOIN nonbrand_test_session_w_landing_page
ON nonbrand_test_session_w_landing_page.website_session_id = nonbrand_test_nounced_session.website_session_id
GROUP BY nonbrand_test_session_w_landing_page.landing_page; 