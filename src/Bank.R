# prepare the R environment
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  dplyr,         # Data munging functions
  zoo,              # Feature engineering rolling aggregates
  data.table,       # Feature engineering
  ggplot2,          # Graphics
  scales,           # Time formatted axis
  readr,            # Reading input files
  stringr,          # String functions
  reshape2,         # restructure and aggregate data 
  randomForest,     # Random forests
  corrplot,         # correlation plots
  Metrics,          # Eval metrics for ML
  vcd               # Visualizing discrete distributions
)

# set options for plots
options(repr.plot.width=6, repr.plot.height=6)
# Load the data
bm <-"C:\\Users\\Mirela\\RStudioProjects\\Marketing\\datasets\\bank-marketing.csv"

if(!file.exists(bm)){tryCatch(bm)}

if(file.exists(bm)) bm_original <- read.csv(bm, header = TRUE, stringsAsFactors = FALSE, sep = ";")

head(bm_original)


# eliminate any duplicates that may exist in the dataset

bank <- bm_original%>%
  distinct(.keep_all = TRUE,age, job, marital, education,balance)


# generate an id column for future use (joins etc)
bank$bank_id = seq.int(nrow(bank))

head(bank)
summary(bank)

bank %>%
  ggplot(mapping = aes(education)) +
  geom_bar(aes(fill=marital), width=1, color="black") +
  theme(legend.position = "bottom", legend.direction = "vertical") + ggtitle("Education vs marital statut")

bank %>%
  dplyr::group_by(age = age) %>%
  dplyr::summarize(
    totalcreditors = n(),
    totalbalances = sum(balance),
    balancespercreditors = totalbalances / totalcreditors
  ) %>%
  ggplot(mapping = aes(x = age, y = balancespercreditors)) +
  geom_point() +
  geom_smooth(method = "loess") + ggtitle("Balances per creditors,vs age")

# what values is our dataset missing?

ggplot_missing <- function(x){
  
  x %>%
    is.na %>%
    melt %>%
    ggplot(mapping = aes(x = Var2,
                         y = Var1)) +
    geom_raster(aes(fill = value)) +
    scale_fill_grey(name = "",
                    labels = c("Present","Missing")) +
    theme(axis.text.x  = element_text(angle=45, vjust=0.5)) +
    labs(x = "Variables in Dataset",
         y = "Rows / observations")
}

ggplot_missing(bank)

summary(bank$balance)

# we can create some aditional features about the matches.
# creditors education type: Tertiary, Primary, Secondary,Unknown

bank$tertiary <- FALSE
bank$tertiary[bank$education == "Tertiary"] <- TRUE

bank$primary <- FALSE
bank$primary[bank$education %like% "Primary"] <- TRUE

bank$secondary <- FALSE
bank$secondary[bank$education %like% "Secondary"] <- TRUE

bank$unknown <- FALSE
bank$unknown[bank$education %like% "Unknown"] <- TRUE

head(bank)

# not use unknown education creditors 

bank <- bank %>% dplyr::filter(unknown == FALSE)

bkmk_perf <- bank %>%
dplyr::mutate(
bal = (balance > 1000),
dtion = (duration < 150),
edumar = (education == "tertiary" & marital == "married")
) %>%
dplyr::select (bank_id,age,job,marital,edumar,bal,housing,dtion)
head(bkmk_perf)

formula_balpercentage <- function(totalcustomers, balance) {
  return ((balance) / totalcustomers)
}

plot_balpercentage <- function(bkmk_perf, mincustomers) {
  bkmk_perf %>%
    group_by(job) %>%
    summarize(
      totalcustomers = n(),
      balance = length(bal[bal==TRUE]),
      balpercentage = formula_balpercentage(totalcustomers, balance)
    ) %>%
    filter(totalcustomers >= mincustomers ) %>%
    ggplot(mapping = aes(x = balpercentage, y = totalcustomers)) +
    geom_point(size = 1.5) + 
    geom_text(aes(label=job), hjust=-.2 , vjust=-.2, size=3) +
    geom_vline(xintercept = .5, linetype = 2, color = "red") +
    ggtitle("Balance Percentage vs Customers") +
    expand_limits(x = c(0,1))
} 

plot_balpercentage(bkmk_perf, 900)

# transform old job names into new ones( with CL).
jobNodeMappings <- matrix(c(
  "management","Management",
  "technician","Technician",
  "entrepreneur","Entrepreneur",
  "blue-collar","Blue-collar",
  "unknown","Unknown",
  "services","Services",
  "retired","Retired"
), ncol=2, byrow = TRUE)

for (i in 1:nrow(jobNodeMappings)) {
  bkmk_perf$job[bkmk_perf$job == jobNodeMappings[i,1]] <- jobNodeMappings[i,2]
  
  bank$job[bank$job == jobNodeMappings[i,1]] <- jobNodeMappings[i,2]
  
}

head(bkmk_perf)

# what is the occurence frequency for martital statut?

maritalfreq <- bank %>%
  group_by(marital,job) %>%
  summarise(
    n = n(),
    freq = n / nrow(bank)
  ) %>%
  ungroup() %>%
  mutate(
    maritaltext = paste(marital,"vs",job)
  ) %>%
  arrange(desc(freq)) 

head(maritalfreq, 15)

# distribution of balance per customer
balancefreq <- bank %>%
  group_by(bal= balance) %>%
  summarise(
    n = n(),
    freq = n / nrow(bank)
  ) %>%
  ungroup() %>%
  arrange(desc(freq)) 

head(balancefreq, 25)

balancefreq %>%
  filter(freq >= 0.001) %>%
  ggplot(mapping = aes(x = bal, y = freq)) + geom_bar(stat = "identity") + ggtitle("Balance  per customer distribution")

# distribution of customer age
agefreq <- bank %>%
  group_by(ctage = age) %>%
  summarise(
    n = n(),
    freq = n / nrow(bank)
  ) %>%
  ungroup() %>%
  arrange(ctage) 

head(agefreq %>% filter(abs(ctage)<=35), 15)

agefreq %>%
  filter(abs(ctage)<=35) %>%
  ggplot(mapping = aes(x = ctage, y = freq)) + geom_bar(stat = "identity") + ggtitle("Customer age distribution")

# how many outliers do we have?
out <- bank %>% dplyr::filter(abs(balance) > 8000)
head(out)
paste(nrow(out), "outliers, or", (nrow(out)/nrow(bank)*100), "% of total.")

# get rid of all the outliers by selecting the balance to [-8000, 8000]
bkmk_perf$bal[bkmk_perf$bal < -8000] <- -8000
bkmk_perf$bal[bkmk_perf$bal > 8000] <- 8000

# job and adjustment coefficients for them

jobs <- as.data.frame(matrix(c(
  "management","0.99",
  "technician","0.75",
  "entrepreneur","0.9",
  "blue-collar","0.8",
  "unknown","0.5",
  "services","0.85",
  "retired","0.8"  
), ncol=2, byrow = TRUE, dimnames = list(NULL, c("job","adjust"))), stringsAsFactors = FALSE)

jobs$job <- as.vector(jobs$job)
jobs$adjust <- as.numeric(jobs$adjust)

bkmk_perf <- bkmk_perf %>%
  dplyr::left_join(jobs, by=c("job")) %>%
  dplyr::select(bank_id,age,job,adjust,marital,edumar,bal,housing,dtion)

# set missing values to 1

bkmk_perf$adjust[is.na(bkmk_perf$adjust)] <- 1

# Let's calculate some lag features           
# we'll take three windows: last 10 customers, last 30 customers, last 50 customers.
# for each window we'll calculate some values

lagfn <- function(data, width) {
  return (rollapplyr(data, width = width + 1, FUN = sum, fill = NA, partial=TRUE) - data)
}

lagfn_per <- function(data, width) {
  return (lagfn(data, width) / width)
}

bankperf_features <- bkmk_perf %>%
  dplyr::arrange(job, age) %>%
  dplyr::group_by(job) %>%
  dplyr::mutate(
    last10customers_bal_per = lagfn_per(bal, 10),
    last30customers_bal_per = lagfn_per(bal, 30),
    last50customers_bal_per = lagfn_per(bal, 50),
    
    last10customers_dtion_per = lagfn_per(dtion, 10),
    last30customers_dtion_per = lagfn_per(dtion, 30),
    last50customers_dtion_per = lagfn_per(dtion, 50),
    
    last10customers_edumar_per = lagfn_per(edumar, 10),
    last30customers_edumar_per = lagfn_per(edumar, 30),
    last50customers_edumar_per = lagfn_per(edumar, 50),
    
    
  ) %>%
  dplyr::select (
    bank_id, age, job,adjust,
    bal, last10customers_bal_per, last30customers_bal_per, last50customers_bal_per,
    dtion, last10customers_dtion_per, last30customers_dtion_per, last50customers_dtion_per,
    edumar,last10customers_edumar_per, last30customers_edumar_per, last50customers_edumar_per
    
  ) %>%
  dplyr::ungroup()

head((bankperf_features %>% dplyr::filter(job == "technician" & age >= '20')), n = 100)
summary(bankperf_features)

# fold per-bank_perf features into per-bank features
bank_features <- bank %>%
  left_join(bankperf_features, by=c("bank_id", "age" = "age")) %>%
  dplyr::select(
    age,marital,education,housing,duration,
    last10customers_bal_per,
    last30customers_bal_per,
    last50customers_bal_per,
    last10customers_dtion_per,
    last30customers_dtion_per,
    last50customers_dtion_per,
    last10customers_edumar_per,
    last30customers_edumar_per, 
    last50customers_edumar_per,
    outcome=balance
  )

head(bank_features)
names(bank_features)

# correlation matrix
cormatrix <- cor(bank_features %>% dplyr::select(-c(marital,education, housing)) )
corrplot(cormatrix, type = "upper", order = "original", tl.col = "black", tl.srt = 45, tl.cex = 0.5)

# create the training formula 
trainformula <- as.formula(paste('outcome',
                                 paste(names(bank_features %>% dplyr::select(-c(age,marital,education, housing,outcome))),collapse=' + '),
                                 sep=' ~ '))
trainformula

# training and testing datasets

data.train1 <- bank_features %>% dplyr::filter(age < '55')
data.test1 <- bank_features %>% dplyr::filter(age>= '55' & age <='71')

nrow(data.train1)
nrow(data.test1)

# train a random forest
model.randomForest1 <- randomForest::randomForest(trainformula, data = data.train1, 
                                                  importance = TRUE, ntree = 200)

summary(model.randomForest1)

randomForest::importance(model.randomForest1, type=1)
randomForest::varImpPlot(model.randomForest1, type=1)

data.pred.randomForest1 <- predict(model.randomForest1, data.test1, predict.all = TRUE)

metrics.randomForest1.mae <- Metrics::mae(data.test1$outcome, data.pred.randomForest1$aggregate)
metrics.randomForest1.rmse <- Metrics::rmse(data.test1$outcome, data.pred.randomForest1$aggregate)

paste("Mean Absolute Error:", metrics.randomForest1.mae)
paste("Root Mean Square Error:",metrics.randomForest1.rmse)

abs_error <- abs(data.test1$outcome - data.pred.randomForest1$aggregate)
plot(abs_error, main="Mean Absolute Error")


