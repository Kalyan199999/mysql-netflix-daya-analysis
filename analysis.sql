use netflix;

show tables;

-- 1. Count the number of Movies vs TV Shows
SELECT 
		type , count(1) as total
FROM netflix_titles
GROUP BY type
ORDER BY total DESC
;
-- The raw dataset contains exactly 6131 Movies and 2676 TV Shows.



-- 2. Find the most common rating for movies and TV shows
WITH type_rating_count AS (
		SELECT 
			type, 
            rating,
            count(1) as cnt
		FROM netflix_titles
		GROUP BY type,rating
		ORDER BY type asc, cnt desc
),
	rating_ranking AS (
		select 
				type , 
				rating,
                cnt,
                DENSE_RANK() OVER ( PARTITION BY type ORDER BY cnt DESC ) as rnk
		from type_rating_count
)

select 
	type,
    rating as most_frequent_rating
 from rating_ranking
where rnk = 1;

-- The most common rating of the both movies and tv shows is 'TV-MA'



-- 3. List all movies released in a specific year and from country India
SELECT * FROM netflix_titles
WHERE  type = 'Movie'
	AND releasing_year = 2017 
	AND lower(country) like '%india%'
ORDER BY title;

-- Fetched all the movies that are released in a specific year(2017) and country is India



-- 4. Find the top 5 countries with the most content on Netflix

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

-- Fetched the Country wise content of top 5 countries
-- USA has contributed the maximum content to Netflix
-- followed by India,UK,Canada and finally Japan


-- 5. Identify the longest movie
SELECT 
		title,
		CAST( SUBSTRING_INDEX(TRIM(duration), ' ', 1) AS UNSIGNED) AS duration_minutes
FROM netflix_titles
WHERE LOWER(type) = 'movie'
ORDER BY duration_minutes DESC
limit 20;

-- Fetch the top 20 movies that are having longest duration 


-- 6. Find content added in the last 5 years from '2021-12-31'
SELECT 
		show_id,
        type,
        title,
        date_added,
        timestampdiff( YEAR, date_added, date('2021-12-31')  ) as years_before_added
FROM netflix_titles
WHERE timestampdiff( YEAR, date_added, date('2021-12-31')  ) <= 5
ORDER BY years_before_added DESC
;

-- Fetches all titles added to the platform within 5 years prior to December 31, 2021.

-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
SELECT 
    title,
    director,
    releasing_year  
FROM netflix_titles
WHERE lower(director) LIKE '%rajiv chilaka%'
ORDER BY releasing_year;

-- or 
SELECT 
		title, 
        director, 
        releasing_year
FROM netflix_titles
WHERE FIND_IN_SET('Rajiv Chilaka', REPLACE(director, ', ', ',')) > 0
ORDER BY releasing_year;

-- The list of both Movies and TV Shows that are directed by Rajiv Chilaka


-- 8. List all TV shows with more than 5 seasons
SELECT 
    title,
     CAST( SUBSTRING_INDEX( TRIM( duration  ) , ' ', 1 ) as UNSIGNED  ) as max_seasons
FROM netflix_titles
WHERE type='TV Show'
AND CAST( SUBSTRING_INDEX( TRIM( duration  ) , ' ', 1 ) as UNSIGNED  ) > 5
ORDER BY max_seasons ASC
;

-- The list of TV Shows that has more than 5 season released


-- 9. Count the number of content items in each genre
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

-- Fetched the movies and shows based on their genre and 
-- arranged on its countings



-- 10.Find each year and the average numbers of content release in India on netflix. 
-- return top 5 year with highest avg content release!
SELECT
		releasing_year as year,
        count(show_id) as total_releases,
        ROUND(
				count(show_id)  / (SELECT count(distinct releasing_year) as distinct_years FROM netflix_titles WHERE country LIKE '%India%') , 2
        ) AS avg_num_movies
        
FROM netflix_titles
WHERE country LIKE '%India%'
GROUP BY releasing_year
ORDER BY avg_num_movies DESC
limit 5
;

-- Year wise the total and the average number of movies released per year in India


-- 11. List all movies that are documentaries
SELECT
		type,
        title,
        listed_in
FROM netflix_titles
WHERE type='Movie' AND lower(listed_in) LIKE '%documentaries%'
;

-- Fetched the only movies that are also documentaries


-- 12. Find all content without a director
SELECT
		*
FROM netflix_titles
WHERE director IS NULL OR director = ''
;

-- These shows and movies doesn't menctioned any director name



-- 13. Find how many movies actor 'Salman Khan' appeared in last 20 years!
SELECT
		*,
        YEAR( CURDATE() ) - releasing_year AS YR
FROM netflix_titles
WHERE cast LIKE '%Salman Khan%'
and  YEAR( CURDATE() ) - releasing_year <= 20
ORDER BY releasing_year
;

-- The list of movies and shows that actor 'Salman Khan' has appered or acted in the last 20 years



-- 14 find out which co-actors appeared most frequently alongside Salman Khan in these movies

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
ORDER BY appearances_together DESC , co_actor ASC;

-- The list of co-actors who apperaed along with 'Salman Khan' in movies in the last 20 years



-- 15. Find the top 10 actors who have appeared in the highest number of movies produced in India.
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
limit 10
;

-- The actors who acted or appered in the maximum movies produced India


-- 16. Categorize the content based on the presence of the keywords 'kill' and 'violence' in  the description field,
-- Label content containing these keywords as 'Bad' and all other 
-- content as 'Good'. Count how many items fall into each category.

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
ORDER BY content_label ASC
;

-- Categorized the movies and shows based on the keyword kill,violence into Bad and Good
-- Then counted the total per each category


