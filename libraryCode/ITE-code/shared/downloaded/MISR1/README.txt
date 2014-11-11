--------------------------------------------------------
--- Multiple Instance Regression Remote Sensing Data ---
--------------------------------------------------------


-------
-MISR1-
-------
- Each row is an instance. Each bag consists of ~100 instances representing randomly selected pixels within 20-kilometer radius around the AERONET site.
- Description:
-- #bags: 800
-- #total instances: 76040
-- #features: 16
-- 1st col: bag ID.
-- 2nd ~ 13rd col: features (12 reflectances from the three middle MISR cameras).
-- 14th ~ 17th col: features (four solar angles).
-- 18th col: bag label (AOD measured by the AERONET instrument; all the instanses in the same bag have the identical label).


-------
-MISR2-
-------
- A cleaner version of the MISR data (Each bag consists of 100 instances representing randomly selected NON-CLOUDY pixels within 20-kilometer radius around the AERONET site.
- Description:
-- #bags: 800
-- #total instances: 80000
-- features are the same as MISR1's.


-------
-MODIS-
-------
- Each bag consists of 100 instances representing randomly selected pixels around the AERONET site.
- Description:
-- #bags: 1364
-- #total instances: 136400
-- #features: 12
-- 1st col: bag ID.
-- 2nd ~ 8th col: features (7 MODIS reflectances).
-- 9th ~ 13th col: features (5 solar and view zenith angles).
-- 14th col: bag label (AOD measured by the AERONET instrument).


------------------
-train/test split-
------------------
The evaluation of algorithms is being done by 5-CV at bags. 



