-- Name: Jane Nguyen
-- Email: kiyotara000pika@gmail.com 

-- DB Setup:
-- In order to load CSV data into PSQL table, run the following:
\copy website_revenue FROM 'website_revenue.csv' DELIMITER ',' CSV HEADER;

-- rename marketing_data schema to correspond with the csv title.
ALTER TABLE marketing_data RENAME TO marketing_performance; 

-- Answers:
-- Question 1: Sum of Impressions by Day

SELECT date AS day, SUM(impressions) AS total_impressions
FROM marketing_performance
GROUP BY day 
ORDER BY day; 


-- Question 2: Top three revenue-generating states in order of best to worst. How much revenue did the third best state generate?
-- Answer: The third best state was OH and generated 37577 in revenue.
SELECT state, SUM(revenue) AS total_revenue
FROM website_revenue
GROUP BY state
ORDER BY total_revenue DESC
LIMIT 3;


-- Question 3: Total cost, impressions, clicks, and revenue of each campaign. Make sure to include the campaign name in the output.

WITH marketing_campaign AS (
    SELECT 
        ci.name, 
        ci.id AS campaign_id,
        ROUND(SUM(mp.cost::numeric), 2) AS total_cost, 
        SUM(mp.impressions) AS total_impressions, 
        SUM(mp.clicks) AS total_clicks
    FROM marketing_performance AS mp
        INNER JOIN campaign_info AS ci
            ON mp.campaign_id = ci.id::varchar
    GROUP BY ci.id, ci.name
),
website_campaign AS (
    SELECT 
        ci.name, 
        ci.id AS campaign_id,
        SUM(wr.revenue) AS total_revenue
    FROM website_revenue AS wr
        INNER JOIN campaign_info AS ci
            ON wr.campaign_id = ci.id::varchar
    GROUP BY ci.id, ci.name  
)
SELECT 
    m.name, 
    m.total_cost,
    m.total_impressions,
    m.total_clicks,
    w.total_revenue
FROM marketing_campaign AS m
    INNER JOIN website_campaign AS w 
        ON m.campaign_id = w.campaign_id
        AND m.name = w.name;


-- Question 4: Number of conversions of Campaign5 by state. Which state generated the most conversions for this campaign?
-- Answer: GA generated the most conversions: 672.

SELECT
    ci.name AS campaign_name,
    SUBSTR(mp.geo, 15, 16) AS campaign_state,
    SUM(mp.conversions) AS total_conversions
FROM marketing_performance mp
    INNER JOIN campaign_info ci
        ON mp.campaign_id = ci.id::varchar
WHERE ci.name = 'Campaign5'
GROUP BY ci.name, mp.geo
ORDER BY total_conversions DESC;


-- Question 5: In your opinion, which campaign wAS the most efficient, and why?
-- Answer: Let's say that the goal of the ad marketing team was to optimize ad revenue per dollar spent, then we 
-- want to use ROAS (Return on Ad Spend) as a measure of efficiency, to determine if enough revenue is being 
-- generated to continue the marketing campaign in question. 

-- ROAS = Conversion Revenue / Advertizing Cost

-- From the calculated answer as shown in the query result, Campaign 5 was the most efficient, generating the 
-- highest volume of ad revenue per dollar spent. 

WITH marketing_campaign AS (
    SELECT 
        ci.name AS campaign_name,
        ci.id AS campaign_id,
        ROUND(SUM(mp.cost::numeric), 2) AS total_cost
    FROM marketing_performance AS mp 
        INNER JOIN campaign_info AS ci 
            ON mp.campaign_id = ci.id::varchar
    GROUP BY ci.id, ci.name
),
website_campaign AS (
    SELECT
        ci.name AS campaign_name, 
        ci.id AS campaign_id,
        SUM(wr.revenue) AS total_revenue
    FROM website_revenue AS wr
        INNER JOIN campaign_info AS ci
            ON wr.campaign_id = ci.id::varchar
    GROUP BY ci.id, ci.name    
)
SELECT 
    m.campaign_name, 
    m.total_cost,
    w.total_revenue,
    ROUND((w.total_revenue::numeric / m.total_cost::numeric), 2) AS return_on_ad_spend
FROM marketing_campaign AS m
    INNER JOIN website_campaign AS w 
        ON m.campaign_id = w.campaign_id
        AND m.campaign_name = w.campaign_name
ORDER BY return_on_ad_spend DESC, campaign_name;

-- Question 6: The best day of the week (e.g., Sunday, Monday, Tuesday, etc.) to run ads.
-- Answer:

-- To determine which day of the week is "best" to run ad, we want to understand what "best" means to us.
-- We might want to consider Conversion Rate, which gives us insights into the number of customers
-- who perform a certain desired action after interacting with our ad. However, the likelihood of a conversion
-- might be influenced by other external factors that do not directly relate to days of the week, for example,
-- the advertizing channel or the ad relevance in relation to the customer interest. And thus, we want to find
-- a metric that is most directly related or influenced by time/day of the week. In this case, we might want to 
-- consider Click Through Rate or Cost Per Mille because they are both reflective of the number of impressions
-- or level of customer engagement with our ad throughout the week. This hinges directly upon the time and day 
-- of the week depending on the characteristics of our target audience. Between the two metrics, however, we
-- might be more interested in calculating the Cost Per Mille, or the cost per every 1,000 impressions made
-- upon viewing our ad. Calculating this metric would help us determine which day of the week yield the highest
-- number of impressions while still keeping cost at a minimal level. Cost Per Mille is also superior to Click
-- Through Rate, in this example, because it is not confounded by other non-time related factors. 
-- For example, Click Through Rate might have still been confounded by other factors like ad relevance.

-- Therefore, using the query below to calculate the CPM, Sunday is the best day to run our ad. 

SELECT 
    TO_CHAR(b.date, 'Day') AS day_of_week,
    AVG(b.cpm) AS avg_cpm
FROM (
    SELECT date,
        (1000 * cost)/impressions AS cpm 
    FROM marketing_performance
    ) as b
GROUP BY day_of_week
ORDER BY avg_cpm DESC;