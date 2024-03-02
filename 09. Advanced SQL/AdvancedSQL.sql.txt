1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».

SELECT COUNT(p.id)
FROM stackoverflow.posts p
LEFT JOIN stackoverflow.post_types pt ON pt.id = p.post_type_id
WHERE pt.type = 'Question' AND (favorites_count >= 100 OR score > 300)


2. Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.

WITH
         count_posts AS 
         (SELECT DATE_TRUNC('DAY',p.creation_date)::DATE,
                          COUNT(p.id) count_posts
         FROM stackoverflow.posts p
         LEFT JOIN stackoverflow.post_types pt ON pt.id = p.post_type_id
         WHERE pt.type = 'Question' 
        AND DATE_TRUNC('DAY',p.creation_date)::DATE BETWEEN '2008-11-01' AND '2008-11-18'
        GROUP BY DATE_TRUNC('DAY',p.creation_date)::DATE)

SELECT ROUND(AVG(count_posts))
FROM count_posts


3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.

SELECT COUNT(DISTINCT u.id)
FROM stackoverflow.users u
JOIN stackoverflow.badges b ON b.user_id = u.id
WHERE b.creation_date::date = u.creation_date::date


4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?

SELECT COUNT(DISTINCT p.id)
FROM stackoverflow.users u
JOIN stackoverflow.posts p ON u.id = p.user_id
JOIN stackoverflow.votes v ON p.id = v.post_id
WHERE u.display_name = 'Joel Coehoorn' 
HAVING COUNT(v.id) >= 1
 

5. Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.

WITH
         RANK AS 
        (SELECT *, 
         ROW_NUMBER() OVER(ORDER BY id DESC) rank
         FROM stackoverflow.vote_types)

SELECT *
FROM RANK
ORDER BY rank DESC


6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.

SELECT u.id users, 
              COUNT(v.id)  count_votes
FROM stackoverflow.users u
JOIN stackoverflow.votes v ON u.id = v.user_id
JOIN stackoverflow.vote_types vt ON v.vote_type_id = vt.id
WHERE vt.name = 'Close'
GROUP BY users
ORDER BY count_votes DESC
LIMIT 10;


7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
		идентификатор пользователя;
		число значков;
		место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.

SELECT user_id,
       COUNT(id),
       DENSE_RANK() OVER( ORDER BY COUNT(id) DESC)
FROM stackoverflow.badges
WHERE DATE_TRUNC('day',creation_date)::date BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY user_id
LIMIT 10


8. Сколько в среднем очков получает пост каждого пользователя?
Сформируйте таблицу из следующих полей:
		заголовок поста;
		идентификатор пользователя;
		число очков поста;
		среднее число очков пользователя за пост, округлённое до целого числа.
Не учитывайте посты без заголовка, а также те, что набрали ноль очков.

SELECT title,
       user_id,
       score,
       ROUND(AVG(score) OVER( PARTITION BY user_id))
FROM stackoverflow.posts
WHERE title IS NOT NULL AND score != 0
GROUP BY title,
                    user_id,
                    score


9. Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.

SELECT title
FROM stackoverflow.posts
WHERE user_id IN
(SELECT user_id
FROM stackoverflow.badges
GROUP BY user_id
HAVING COUNT(id) > 1000) AND title IS NOT NULL


10. Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
		пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
		пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
		пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.

SELECT id,
               views,
               CASE
                        WHEN views >= 350 THEN 1
                        WHEN views < 350 AND views >= 100 THEN 2
                        ELSE 3
               END
FROM stackoverflow.users
WHERE location LIKE ('%Canada%') AND views > 0;


11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. Выведите поля с идентификатором пользователя, группой и количеством просмотров. Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.

SELECT id,
      cass, 
      max
FROM (SELECT id, 
             cass,
             views,
             MAX(views) OVER( partition by cass ) max
       FROM 
           (SELECT id,
                    views,
                    CASE
                        WHEN views >= 350 THEN 1
                        WHEN views < 350 AND views >= 100 THEN 2
                        ELSE 3
                    END AS cass
             FROM stackoverflow.users
             WHERE location LIKE ('%Canada%') AND views > 0) AS GAG) AS DSA
WHERE max = views
ORDER BY views DESC, id




12. Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
		номер дня;
		число пользователей, зарегистрированных в этот день;
		сумму пользователей с накоплением.


WITH 
    g as 
    (SELECT DISTINCT EXTRACT(DAY FROM creation_date) AS day,
            COUNT(id)
     FROM stackoverflow.users
     WHERE DATE_TRUNC('day', creation_date) BETWEEN '2008-11-01' and '2008-11-30'
     GROUP BY day)

SELECT *,
       SUM(count) OVER(ORDER BY day)
FROM g



13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
		идентификатор пользователя;
		разницу во времени между регистрацией и первым постом.

WITH 
        rank AS 
        (SELECT *,
              ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY creation_date) rank
         FROM stackoverflow.posts )

SELECT rank.user_id,
               rank.creation_date - u.creation_date
FROM rank
LEFT JOIN  stackoverflow.users u ON u.id = rank.user_id
WHERE rank = 1


1
18



