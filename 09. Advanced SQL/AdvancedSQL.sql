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


14. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.

SELECT DATE_TRUNC('MONTH', creation_date)::DATE,
               SUM(views_count)
FROM stackoverflow.posts
GROUP BY DATE_TRUNC('MONTH', creation_date)
ORDER BY SUM(views_count) DESC


15. Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений `user_id`. Отсортируйте результат по полю с именами в лексикографическом порядке.

WITH 
        a AS (
        SELECT user_id,
                      creation_date::date AS post_date
        FROM stackoverflow.posts
        WHERE post_type_id = 2 ),

        b AS (
        SELECT id,
                      creation_date::date AS rgs_date,
                     display_name
        FROM stackoverflow.users )

SELECT  b.display_name,
                COUNT(DISTINCT b.id) AS user_count
FROM a 
JOIN b ON a.user_id = b.id
WHERE a.post_date <= b.rgs_date + INTERVAL '1 month'
GROUP BY b.display_name
HAVING COUNT(*) > 100
ORDER BY b.display_name;


16. Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.

SELECT DATE_TRUNC('MONTH', creation_date)::date,
               COUNT(id)
FROM stackoverflow.posts
WHERE user_id IN 
                            (SELECT posts.user_id
                             FROM stackoverflow.users
                             JOIN stackoverflow.posts ON posts.user_id = users.id
                             WHERE  EXTRACT(MONTH FROM users.creation_date) = 09
                             AND EXTRACT(MONTH FROM posts.creation_date) = 12)
GROUP BY DATE_TRUNC('MONTH', creation_date)::date
ORDER BY DATE_TRUNC('MONTH', creation_date)::date DESC


17. Используя данные о постах, выведите несколько полей:
		идентификатор пользователя, который написал пост;
		дата создания поста;
		количество просмотров у текущего поста;
		сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.

SELECT user_id,
               creation_date,
               views_count,
              SUM(views_count) OVER(PARTITION BY user_id ORDER BY creation_date)
FROM stackoverflow.posts
ORDER BY user_id


18. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число — не забудьте округлить результат.

SELECT ROUND(AVG(count))
FROM (SELECT DISTINCT user_id,
       COUNT(DISTINCT creation_date) count
FROM stackoverflow.posts
WHERE last_edit_date::date BETWEEN '2008-12-01' AND '2008-12-07'
GROUP BY user_id
) AS count_posts;


19. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
		Номер месяца.
		Количество постов за месяц.
		Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.
Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз. Чтобы этого избежать, переведите делимое в тип `numeric`.

WITH 
        count_posts AS (
        SELECT EXTRACT(MONTH FROM creation_date) date,
                       COUNT(DISTINCT id) count   
FROM stackoverflow.posts 
WHERE EXTRACT(MONTH FROM creation_date) BETWEEN 09 AND 12
GROUP BY DATE)

SELECT *,
              ROUND((count::numeric / LAG(count, 1) OVER(ORDER BY date)-1)*100, 2)
FROM count_posts


20. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. Выведите данные его активности за октябрь 2008 года в таком виде:
		номер недели;
		дата и время последнего поста, опубликованного на этой неделе.

WITH 
        active_user AS (
        SELECT user_id,
                      COUNT(id) 
        FROM stackoverflow.posts
        GROUP BY user_id
        ORDER BY COUNT(id) DESC
        LIMIT 1),

       date AS (
       SELECT p.creation_date date,
                      EXTRACT(WEEK FROM p.creation_date ) week
       FROM active_user
       LEFT JOIN stackoverflow.posts p ON p.user_id = active_user.user_id
       WHERE p.creation_date::date BETWEEN '2008-10-01' AND '2008-10-31'),

       last AS (
       SELECT week,
                      MAX(date) OVER(PARTITION BY week) last_post
       FROM date)

SELECT week, 
               last_post
FROM last
GROUP BY week, 
                    last_post
