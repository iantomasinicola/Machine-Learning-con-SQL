CREATE DATABASE MachineLearning
GO
USE MachineLearning


--------------------
--IMPORT DEI DATI
---------------------
CREATE TABLE dbo.Iris(Rownumber INT PRIMARY KEY NOT NULL,
sepal_length DECIMAL(18,4),
sepal_width DECIMAL(18,4),
petal_length DECIMAL(18,4),
petal_width DECIMAL(18,4),
class VARCHAR(255) NOT NULL);

BULK INSERT dbo.Iris
FROM 'C:\Users\ianto\Desktop\Machine learning SQL\IrisDataset.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ';',
ROWTERMINATOR = '\n');


--------------------
--CODIFICA CLASSI
---------------------
UPDATE dbo.Iris
SET class = 1
WHERE class = 'Iris setosa';

UPDATE dbo.Iris
SET class = -1
WHERE class = 'Iris versicolor';


-----------------------------
--DIVISIONE TRAINING E TEST
-----------------------------
ALTER TABLE dbo.Iris ADD IsTraining INT;

UPDATE dbo.Iris
SET IsTraining = 1;

UPDATE dbo.Iris
SET IsTraining = 0
WHERE Rownumber IN (
SELECT TOP 30 PERCENT Rownumber
FROM dbo.Iris
ORDER BY CHECKSUM(NEWID())
);


--------------------
--GESTIONE NULL
--------------------
DECLARE @AVG_sepal_length DECIMAL(18,2), @AVG_sepal_width DECIMAL(18,2), @AVG_petal_length DECIMAL(18,2), @AVG_petal_width DECIMAL(18,2);

SELECT @AVG_sepal_length = AVG(sepal_length),
@AVG_sepal_width = AVG(sepal_width),
@AVG_petal_length = AVG(petal_length),
@AVG_petal_width = AVG(petal_width)
FROM dbo.Iris
WHERE IsTraining = 1;


UPDATE dbo.Iris
SET          sepal_length = @AVG_sepal_length
WHERE sepal_length IS NULL;

UPDATE dbo.Iris
SET         sepal_width = @AVG_sepal_width
WHERE sepal_width IS NULL;

UPDATE dbo.Iris
SET          petal_length = @AVG_petal_length
WHERE petal_length IS NULL;

UPDATE dbo.Iris
SET          petal_width = @AVG_petal_width
WHERE  petal_width IS NULL;


--------------------
--NORMALIZZAZIONE
---------------------
DECLARE @AVG_sepal_length DECIMAL(18,2), @AVG_sepal_width DECIMAL(18,2), @AVG_petal_length DECIMAL(18,2), @AVG_petal_width DECIMAL(18,2), @DV_sepal_length DECIMAL(18,2), @DV_sepal_width DECIMAL(18,2), @DV_petal_length DECIMAL(18,2), @DV_petal_width DECIMAL(18,2)

SELECT  @AVG_sepal_length = AVG(sepal_length),
@AVG_sepal_width = AVG(sepal_width),
@AVG_petal_length = AVG(petal_length),
@AVG_petal_width = AVG(petal_width),
@DV_sepal_length = STDEVP(sepal_length),
@DV_sepal_width = STDEVP(sepal_width),
@DV_petal_length = STDEVP(petal_length),
@DV_petal_width = STDEVP(petal_width)
FROM dbo.Iris
WHERE IsTraining = 1;

UPDATE dbo.Iris
SET          sepal_length = (sepal_length - @AVG_sepal_length) / @DV_sepal_length,
sepal_width= (sepal_width- @AVG_sepal_width) / @DV_sepal_width,
petal_length = (petal_length - @AVG_sepal_length) / @DV_petal_length,
petal_width = (petal_width - @AVG_petal_width) / @DV_petal_width



------------------------
--AGGIUNTA COLONNA PESO
-------------------------
ALTER TABLE dbo.Iris ADD Weight DECIMAL(18,2);
GO
UPDATE dbo.Iris
SET Weight = 1;

--------------------------------
--INIZIALIZZAZIONE PERCEPTRON
--------------------------------
CREATE TABLE w (w0 decimal(18,2),
w1 decimal(18,2),
w2 decimal(18,2),
w3 decimal(18,2),
w4 decimal(18,2));

INSERT INTO w (w0, w1, w2, w3, w4)
VALUES (0,0,0,0,0);

----------------------------------
--IMPLEMENTAZIONE DEL PERCEPTRON
----------------------------------
CREATE PROCEDURE dbo.Perceptron
AS
BEGIN

--inizializziamo il vettore w
UPDATE W
SET w0 = 0, w1 = 0, w2 = 0, w3 = 0, w4 = 0;

--creiamo una variabile I per iterare il procedimento un certo numero di volte
DECLARE @I INT = 1

--decidiamo di ripetere il procedimento per un totale di 10 volte
WHILE @I < 10
BEGIN
	--dichiariamo una variabile per salvare la predizione effettuata
	DECLARE @predizione DECIMAL(18,2);

	--dichiariamo una variabile per salvare la classe reale
	DECLARE @y DECIMAL(18,2);

	--dichiariamo una variabile per salvare la riga in lavorazione ad ogni iterazione
	DECLARE @RowNumber INT;

	--dichiariamo un cursore contenente le righe del dataset di Training ordinate in modo randomico
	DECLARE cursore CURSOR
	FOR SELECT RowNumber
	FROM dbo.Iris
	WHERE IsTraining = 1
	ORDER BY RowNumber;

	--apriamo il cursore
	OPEN cursore

	--inseriamo il valore corrente del cursore nella variabile @RowNumber
	FETCH NEXT FROM cursore INTO @RowNumber;

	--ripetiamo il procedimento finché ci sono righe nel cursore
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--calcoliamo la predizione valutando se il prodotto scalere è maggiore o minore di zero
		--salviamo inoltre il valore reale della classe nella variabile @y
		SELECT @Predizione = CASE WHEN sepal_length*w0
		                    +sepal_width*w1
							+petal_length*w2
							+petal_width*w3
							+weight*w4 >= 0
							THEN 1
							ELSE -1
							END,
				@y = class
		FROM dbo.Iris
		CROSS JOIN w
		WHERE RowNumber = @RowNumber;

		--aggiornamento il vettore w
		UPDATE w
		SET w0 = w0 + 0.1*(@y-@predizione)*sepal_length,
			w1 = w1 + 0.1*(@y-@predizione)*sepal_width,
			w2 = w2 + 0.1*(@y-@predizione)*petal_length,
			w3 = w3 + 0.1*(@y-@predizione)*petal_width,
			w4 = w4 + 0.1*(@y-@predizione)*weight
		FROM w AS w
		CROSS JOIN (SELECT *
		FROM dbo.Iris
		WHERE RowNumber = @RowNumber) AS A

		--valorizziamo @RowNumber con la riga seguente del cursore
		FETCH NEXT FROM cursore INTO @RowNumber;
	END

	--chiudiamo e deallochiamo il cursore
	CLOSE cursore
	DEALLOCATE cursore

	--incrementiamo il numero di iterazioni
	SET @I = @I + 1
END

SELECT * FROM dbo.w;

END

-------------------------
--ESECUZIONE PERCEPTRON
-------------------------
EXEC dbo.Perceptron



------------------------------------------
--CALCOLO PREVISIONI SU DATI DI TEST
------------------------------------------
SELECT Iris.RowNumber,
	CASE WHEN Iris.class = 1 
		 THEN 'Iris Setosa' 
		 ELSE 'Iris Versicolor' 
	END AS classe,
	CASE WHEN sepal_length*w0+sepal_width*w1+
			  petal_length*w2+petal_width*w3+weight*w4 >= 0
		 THEN 'Iris Setosa' 
		 ELSE 'Iris Versicolor' 
	END AS Predizione
FROM dbo.Iris
CROSS JOIN w
WHERE IsTraining = 0;