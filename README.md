	Intro

	What is this repository for?

We're going to use historical information about bank - marketing to build a model, which is going to give us the ability to predict future results regarding balance for the bank clients.

In R language I can deal with missing values; working with categorical variables; robust models (which deal with outliers); 

Basic concepts of machine learning

How the data is prepared (the most important step)
The data processing and neural network technology choice

Neural networks are data structures that resemble brain cells called neurons. Since discovered that a brain has special cells named neurons that communicate with other neurons by electrical impulses through “lines” called axons. If stimulated sufficiently (from many other neurons) the neurons will trigger an electric impulse further away in this “network” stimulating other neurons.
Computer algorithms try to replicate this biological process.
In computer, neural nets each neuron has a “trigger point” where if stimulated over that point it will propagate the stimulation forward, if not it would not. For this, each simulated neuron will have a bias, and each axon a weight. After a random initialization of these values a process called “learning” starts this means in a loop algorithm will do this steps:

    Stimulate the input neurons
    Propagate the signals through the network layers until the output neurons
    Read the output neurons and compare the results with the desired results
    Tweak the axons weights for a better result next time
    Start again until the number of loops has been reached
    One more thing, here well be using a supervised learning method. That means we'll teach the algorithm the inputs and the outputs also, so that given a new set of inputs it can predict the output.

How the data is prepared (the most important step)

In many machine learning and neural network problems data preparation is a very important part and it will cover:

    Get the raw data
    Data clean-up: this will mean removing orphan values, aberrations or other anomalies
    Data grouping: taking many data points and transforming into an aggregated data point
    Data enhancing: adding other aspects of the data derived from own, or from external sources
    Splitting the data in train and test data
    Split each of the train and test data into inputs and outputs.
    Typically, a problem will have many inputs and a few outputs
    Rescale the data so it’s between 0 and 1 (this will help the network removing high/low biases)
    Getting the raw data
    Data clean-up
    The empty values in the data frame are dropped
    Data grouping and data enhancing
    Splitting the data in train and test data
    Split each of the train and test data into inputs and outputs.

The Data
We're going to use a dataset containing more than forty-thousand clients of the bank.The dataset is available as CSV files.

Getting the raw data
In our case getting data for a CSV file in R language is really easy with this lines of code:

if(!file.exists(bm)){tryCatch(bm)}

if(file.exists(bm)) bm_original <- read.csv(bm, header = TRUE, stringsAsFactors = FALSE, sep = ";")

Data cleanup

First let's perform some basic cleanup on the dataset and eliminate any duplicates that may exist in the dataset, generate an id column for future use (joins etc).

Data Exploration and Visualisation

The best way to understand a dataset is to turn it into multiple pictures.
Fortunately, R has some useful tools in this regard - and a lot of them come with the very popular ggplot2 package

Data grouping & data enhancing

Now, we can create some aditional features about the education of the clients eliminate the clients with unknown education from the dataset. 

p until this point we've only looked at individual client. However, what we really need is to look at each client's performance over its history.

When we build our predictive model, we'd like to supply it with as many features about each client to be involved . For that, we need to have a bank - performance dataset with historical data.

Data cleanup again.

transform old job names into new ones( with CL).

Data visualisation again

  what is the occurence frequency for martital statut?
  distribution of balance per customer
  distribution of customer age
  
Data clean up again

I'd like to get rid of outliers - values which are far away at the end of the spectrum of possible values for this variable. The reason is that outliers can drastically change the results of the data analysis and statistical modeling. Outliers increase the error variance, reduce the power of statistical tests, and ultimately they can bias or influence estimates.

  get rid of all the outliers by selecting the balance to [-8000, 8000]
  job and adjustment coefficients for them
  set missing values to 1
 
 Data grouping & data enhancing 
  
  Feature Engineering

Now, let's calculate some lag features for the clients of the bank.

We'll look at the previous N clients, and we'll calculate the percentage of bal, dtion, edumar for those past N clients.
  


