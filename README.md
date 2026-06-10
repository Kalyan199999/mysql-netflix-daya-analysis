# Netflix Movies & TV Shows Data Analysis Using MySQL

## 📌 Project Overview
This project presents a comprehensive, end-to-end data analysis of Netflix's library content up to 2022 using **MySQL**. Designed to tackle the complexities of unnormalized datasets, this project utilizes advanced SQL techniques to clean, transform, and extract structural business insights from comma-separated data strings. 

The analysis investigates content production distributions, target audience demographic splits, historical platform ingest patterns, specific actor/director networks, and textual sentiment filtering.

---

## 🛠️ Tech Stack & Advanced SQL Concepts Used
* **Database Engine:** MySQL
* **Advanced Querying Techniques:**
  * **Recursive CTEs (Common Table Expressions):** Implemented to dynamically unnest multi-valued comma-separated attributes (e.g., parsing individual actors from a combined `cast` list or extracting distinct countries).
  * **Window Functions:** Leveraged `DENSE_RANK() OVER (PARTITION BY ... ORDER BY ...)` to locate peak localized frequencies within multi-categorical groups.
  * **String & Data Manipulation:** Applied `SUBSTRING_INDEX`, `LOCATE`, `FIND_IN_SET`, `REPLACE`, and explicit `CAST` expressions to sanitize dirty data formats on the fly.
  * **Date-Time & Interval Calculations:** Utilized `TIMESTAMPDIFF` and explicit system date evaluations to accurately calculate historical platform growth metrics.
  * **Conditional Logical Framing:** Structured programmatic `CASE WHEN` clauses to simulate semantic text classifications on free-form text blocks.

---

## 📋 Comprehensive Business Problems List
The project addresses and answers the following **16 core business problems**, structured as a progression from baseline statistics to advanced multi-layer relational aggregations:

1. **Content Split Analysis:** Count the exact distribution of Movies vs. TV Shows across the entire dataset.
2. **Audience Target Mapping:** Discover the single most frequent content rating category for both Movies and TV Shows.
3. **Geographical Filter Operations:** List all movies released in a target year (e.g., 2017) specifically matching the country footprint of India.
4. **Global Content Production Hubs:** Isolate and rank the top 5 countries contributing the maximum atomic volume of content items to the global platform.
5. **Runtime Outlier Tracking:** Identify and rank the top 20 longest feature-length movies hosted on the platform.
6. **Platform Ingest Influx Rate:** Detect and list all content added to Netflix's catalogue within a specific 5-year operational block prior to a set cutoff date (`2021-12-31`).
7. **Creator Content Footprint:** Query and display all entries (Movies or TV Shows) credited to a specific multi-disciplinary creator/director (e.g., 'Rajiv Chilaka').
8. **High-Engagement Multi-Season Television:** Filter out and order all long-standing TV series containing greater than 5 active production seasons.
9. **Categorical Genre Density Allocation:** Parse, separate, and count the total number of individual content items grouped under every unique descriptive genre.
10. **Regional Longitudinal Performance Profiles:** Calculate the total yearly content releases within an explicit country (India) and scale it against historical operational metrics to evaluate release volume peaks.
11. **Niche Categorical Filtering:** Isolate and return a clean list of all movies specifically catalogued under the 'Documentaries'.
12. **Metadata Completeness Audits:** Uncover data gaps by fetching a master list of all titles lacking explicitly named director records.
13. **High-Profile Talent Historical Longevity:** Quantify and return every movie or show where a specific leading actor (e.g., 'Salman Khan') appeared over a historical 20-year timeline.
14. **Co-Star Network Mapping & Frequency Tracking:** Unpack the network graph to find out which co-actors appeared most frequently alongside a primary actor within specified movie filter bounds.
15. **Target Region Industry Talent Leaders:** Identify the top 10 unique actors who have appeared in the absolute highest volume of platform content produced within a specific country (India).
16. **Semantic Content Sentiment Classification:** Analyze raw string plots and group items into discrete target safety tags ('Good' vs 'Bad') depending on the presence of safety keywords like 'kill' or 'violence', summarizing their baseline volume count.

---

## 💻 Detailed SQL Queries & Result Notes

### Query 1: Count the number of Movies vs TV Shows
```sql
SELECT 
    type, 
    COUNT(1) AS total
FROM netflix_titles
GROUP BY type
ORDER BY total DESC;
```
* **Result:** Result Note: There are a total of 6,131 Movies and 2,676 TV Shows natively present within the standard dataset baseline, demonstrating a heavy operational platform bias toward feature films (~2.3x more movies).
---


### Query 2: Find the most common rating for movies and TV shows
``` sql
WITH type_rating_count AS (
    SELECT 
        type, 
        rating,
        COUNT(1) AS cnt
    FROM netflix_titles
    GROUP BY type, rating
    ORDER BY type ASC, cnt DESC
),
rating_ranking AS (
    SELECT 
        type, 
        rating,
        cnt,
        DENSE_RANK() OVER (PARTITION BY type ORDER BY cnt DESC) AS rnk
    FROM type_rating_count
)
SELECT 
    type,
    rating AS most_frequent_rating
FROM rating_ranking
WHERE rnk = 1;
```

* **Result:** The most common rating across both Movies and TV Shows is universally 'TV-MA' (Mature Audience), signaling a platform focus on older, mature demographics.
---


### Query :3 List all movies released in a specific year and from country India
``` sql
SELECT * FROM netflix_titles
WHERE type = 'Movie'
  AND releasing_year = 2017 
  AND LOWER(country) LIKE '%india%'
ORDER BY title;
```

* **Result:** Successfully fetches and alphabetizes all Indian feature films released in the specific calendar year of 2017
---



### Query 4: Find the top 5 countries with the most content on Netflix
``` sql
WITH RECURSIVE split_countries AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(country, ',', 1)) AS single_country,
        SUBSTRING(country, LOCATE(',', country) + 1) AS remaining_countries
    FROM netflix_titles
    WHERE country IS NOT NULL AND country != ''
    
    UNION ALL
    
    SELECT 
        TRIM(SUBSTRING_INDEX(remaining_countries, ',', 1)),
        IF(LOCATE(',', remaining_countries) > 0, 
           SUBSTRING(remaining_countries, LOCATE(',', remaining_countries) + 1), 
           '')
    FROM split_countries
    WHERE remaining_countries != ''
)
SELECT 
    single_country AS country,
    COUNT(*) AS total_content
FROM split_countries
WHERE single_country != ''
GROUP BY single_country
ORDER BY total_content DESC
LIMIT 5;
```

* **Result:** Dynamically unpacks co-produced content strings to compile normalized geographical rankings[cite: 1]. The USA contributes the highest overall volume of content, followed consecutively by India, the UK, Canada, and Japan
---



### Query 5: Identify the longest movie
``` sql
SELECT 
    title,
    CAST(SUBSTRING_INDEX(TRIM(duration), ' ', 1) AS UNSIGNED) AS duration_minutes
FROM netflix_titles
WHERE LOWER(type) = 'movie'
ORDER BY duration_minutes DESC
LIMIT 20;
```

* **Result:** Extracts the runtime string suffix, casts the raw metric into a sortable unsigned integer, and returns the top 20 longest standalone films available.
---



### Query 6: Find content added in the last 5 years
``` sql
SELECT 
    show_id,
    type,
    title,
    date_added,
    TIMESTAMPDIFF(YEAR, date_added, DATE('2021-12-31')) AS years_before_added
FROM netflix_titles
WHERE TIMESTAMPDIFF(YEAR, date_added, DATE('2021-12-31')) <= 5
ORDER BY years_before_added DESC;
```

* **Result:** Correctly isolates and monitors the platform ingestion velocity by identifying all titles added to the Netflix catalogue within the 5 rolling years prior to the specified target date baseline (2021-12-31)
---



### Query 7: Find all the movies/TV shows by director 'Rajiv Chilaka'
``` sql
SELECT 
    title,
    director,
    releasing_year  
FROM netflix_titles
WHERE LOWER(director) LIKE '%rajiv chilaka%'
ORDER BY releasing_year;

-- ALTERNATIVE IN-SET MATCHING PATTERN:
SELECT 
    title, 
    director, 
    releasing_year
FROM netflix_titles
WHERE FIND_IN_SET('Rajiv Chilaka', REPLACE(director, ', ', ',')) > 0
ORDER BY releasing_year;
```

* **Result:** Since the query checks global titles without filtering the type column explicitly, this returns the consolidated timeline of both Movies and TV Shows/Animation series directed by Rajiv Chilaka
---



### Query 8: List all TV shows with more than 5 seasons
``` sql
SELECT 
    title,
    CAST(SUBSTRING_INDEX(TRIM(duration), ' ', 1) AS UNSIGNED) AS max_seasons
FROM netflix_titles
WHERE type = 'TV Show'
  AND CAST(SUBSTRING_INDEX(TRIM(duration), ' ', 1) AS UNSIGNED) > 5
ORDER BY max_seasons ASC;
```

* **Result:** Filters out highly successful multi-season television IPs that have surpassed the 5-season threshold, serving as a solid benchmark for analyzing high-retention content.
---



### Query 9: Count the number of content items in each genre
``` sql
WITH RECURSIVE split_genres AS (
    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(listed_in, ',', 1)) AS genre,
        SUBSTRING(listed_in, LENGTH(SUBSTRING_INDEX(listed_in, ',', 1)) + 2) AS remaining
    FROM netflix_titles
    WHERE listed_in IS NOT NULL AND listed_in != ''

    UNION ALL

    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS genre,
        IF(
            LOCATE(',', remaining) > 0, 
            SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2), 
            ''
        ) AS remaining
    FROM split_genres
    WHERE remaining != ''
)
SELECT 
    genre,
    COUNT(*) AS total_content
FROM split_genres
WHERE genre != ''
GROUP BY genre
ORDER BY total_content DESC;
```

* **Result:** Unfolds complex comma-separated nested genres (e.g., "International Movies, Thrillers") into discrete atomic records to compile an accurate total content density analysis per genre.
---



### Query 10: Find each year and the average numbers of content release in India on netflix. Return top 5 years with highest avg content release!
``` sql
SELECT
    releasing_year AS year,
    COUNT(show_id) AS total_releases,
    ROUND(
        COUNT(show_id) / (SELECT COUNT(DISTINCT releasing_year) AS distinct_years FROM netflix_titles WHERE country LIKE '%India%'), 2
    ) AS avg_num_movies
FROM netflix_titles
WHERE country LIKE '%India%'
GROUP BY releasing_year
ORDER BY avg_num_movies DESC
LIMIT 5;
```

* **Result:** Calculates each year's volumetric output scaled against a global constant representing India's historical release footprint[cite: 1]. Since the denominator is static, the resulting list maps out the top 5 years boasting the single highest total volume of Indian releases
---



### Query 11: List all movies that are documentaries
``` sql
SELECT
    type,
    title,
    listed_in
FROM netflix_titles
WHERE type = 'Movie' AND LOWER(listed_in) LIKE '%documentaries%';
```

* **Result:** Extracts an isolated catalog sub-list containing exclusively non-fiction/documentary films
---



### Query 12: Find all content without a director
``` sql
SELECT * FROM netflix_titles
WHERE director IS NULL OR director = '';
```

* **Result:** Audits metadata health by isolating records missing clear director names[cite: 1]. This list provides target records for future database augmentation or third-party API enrichment.
---



### Query 13: Find how many movies actor 'Salman Khan' appeared in last 20 years!
``` sql
SELECT
    *,
    YEAR(CURDATE()) - releasing_year AS YR
FROM netflix_titles
WHERE cast LIKE '%Salman Khan%'
  AND YEAR(CURDATE()) - releasing_year <= 20
ORDER BY releasing_year;
```

* **Result:** Generates a comprehensive 20-year rolling timeline tracking all listed movies and shows featuring leading actor Salman Khan.
---



### Query 14: Find out which co-actors appeared most frequently alongside Salman Khan in these movies
``` sql
WITH RECURSIVE split_cast AS (
    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS actor,
        SUBSTRING(cast, LENGTH(SUBSTRING_INDEX(cast, ',', 1)) + 2) AS remaining
    FROM netflix_titles
    WHERE type = 'Movie'
      AND cast LIKE '%Salman Khan%'
      AND (YEAR(CURDATE()) - releasing_year) <= 20

    UNION ALL

    SELECT 
        show_id,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS actor,
        IF(
            LOCATE(',', remaining) > 0, 
            SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2), 
            ''
        ) AS remaining
    FROM split_cast
    WHERE remaining != ''
)
SELECT 
    actor AS co_actor,
    COUNT(*) AS appearances_together
FROM split_cast
WHERE actor != '' 
  AND actor != 'Salman Khan'
GROUP BY actor
ORDER BY appearances_together DESC, co_actor ASC;
```

* **Result:** Due to the anchor filter constraint (WHERE type = 'Movie'), this query isolates and maps the precise network frequency ranking of co-stars appearing alongside Salman Khan strictly within Feature Movies over the last 20 years.
---



### Query 15: Find the top 10 actors who have appeared in the highest number of movies produced in India
``` sql
WITH RECURSIVE actors AS (
    SELECT 
        country,
        TRIM(SUBSTRING_INDEX(cast, ',', 1)) AS actor,
        SUBSTRING(cast, LENGTH(SUBSTRING_INDEX(cast, ',', 1)) + 2) AS remaining
    FROM netflix_titles
    WHERE country LIKE '%India%'
      AND cast IS NOT NULL
      AND cast != ''
    
    UNION ALL
    
    SELECT 
        country,
        TRIM(SUBSTRING_INDEX(remaining, ',', 1)) AS actor,
        IF(
            LOCATE(',', remaining) > 0, 
            SUBSTRING(remaining, LENGTH(SUBSTRING_INDEX(remaining, ',', 1)) + 2), 
            ''
        ) AS remaining
    FROM actors
    WHERE remaining != ''
)
SELECT 
    actor,
    COUNT(*) AS total_appearances
FROM actors
WHERE actor != ''
GROUP BY actor
ORDER BY total_appearances DESC
LIMIT 10;
```

* **Result:** Unnests multi-valued strings to calculate exact global performance metrics, returning a clean roster of the top 10 most prolific acting talents within the Indian film sector on Netflix.
---

### Query 16: Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field, label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category.
``` sql
SELECT
    content_label,
    COUNT(*) AS total_count
FROM (
    SELECT
        title,
        CASE 
            WHEN LOWER(description) LIKE '%kill%' OR LOWER(description) LIKE '%violence%' THEN 'Bad'
            ELSE 'Good'
        END AS content_label
    FROM netflix_titles
) AS sub_query
GROUP BY content_label
ORDER BY content_label ASC;
```

* **Result:** Uses targeted pattern matching (CASE WHEN LIKE) to classify descriptions into text maturity groups ('Good' vs 'Bad') and returns a summary count of each tier to help gauge general content safety benchmarks.

---

---

## ⚙️ Installation & Setup Guide

To replicate this analysis locally, follow these steps:

### 1. Clone the Repository
```bash
git clone [https://github.com/your-username/netflix-sql-analysis.git](https://github.com/your-username/netflix-sql-analysis.git)
cd netflix-sql-analysis


# ### 🛠️ Final Assembly Check
# Once you paste this right at the bottom of the file we generated earlier, your repo will have:
# 1. Clear **Project Overview**
# 2. Impressive **Advanced SQL concepts list** (Recursive CTEs, Window Functions)
# 3. Full **16 Business Problems index**
# 4. All **16 SQL queries and verified insights**
# 5. Step-by-step **Installation guide** 
# 6. Transparent **Schema structure table**

# Save it, commit it, and you're ready to share your link with developers and recruiters!