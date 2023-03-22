# Spatial-Simulation (Decision Support System)
Determine the ideal cattle size that can accommodate the vierkaser pasture using an agent-based modelling approach

<h2>1. Introduction</h2>
<br>
One of the pillars of effective grazing management is a good cow-to-land ratio. Determining the area of the pasture is one issue that farmers have. While farmers with little land who wish to know how many cows can fit on a certain strip of land, Farmers with bigger tracts of land would also need to be aware of the bare minimum of space required for continuous grazing of their livestock. Good grazing management requires striking the correct balance between your herd size and the available feed.

<h2>1.1 Research question</h2>
What is the ideal cattle size that can accommodate the Vierkaser pasture while covering its daily feeding intake?

<h2>1.2 Aim</h2> 
This project aim to develop an agent based decision support system that can determine the ideal cattle size for the Vierkaser pasture based on the type of cows and the size of the pasture.

<h2>1.3. Objectives</h2>
<ol>
<li>Model the cows behavior (grazing, rumination and sleep) in day and night.</li>
<li>Model cellular automata simulation for pasture cells (growth and biomass loss).</li>
<li>Determine the ideal herd size for the pasture.</li></ol>

<h2>2.1 Sample results</h2>

![image](https://user-images.githubusercontent.com/34416550/226987168-0bc6de30-09ad-4ea5-ae15-c7ac0e5efa54.png)
![image](https://user-images.githubusercontent.com/34416550/226987209-2fa447f6-d834-41e8-a04c-71494ddbb256.png)

The implemented Decision Support system has 5 primary parameters to select before starting the model; one for the selection of scenario which denote the movement of cows, and 4 more parameters to indicate number of cows in each category. In addition to the time series of each cow’s consumption, the results will automatically write into a csv file which can be used for further analysis. Also, at the end of each day, the status of each cows’ daily fulfillment data also output into the console (Cow identifier, consumed biomass, whether target reached or not, day and each cows’ daily requirement). The constant progression of certain time intervals denotes the time cows stope grazing (resting or achieved daily requirement).


