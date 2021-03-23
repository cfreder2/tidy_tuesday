
library("tidyverse")
library("janitor")
library("devtools")
library("stringdist")

library("tidytuesdayR")
tuesdata <- tidytuesdayR::tt_load('2021-01-26')
plastics <- tuesdata$plastics %>% janitor::clean_names()
plastics %>% filter(parent_company == "Grand Total") 

# Humans entering company names == PROBLEMS
plastics %>% filter(str_detect(str_to_lower(plastics$parent_company),"johnson"))                    

# We need to normalize these company names.  How to tell if two companies are the same???

#The distance is a generalized Levenshtein (edit) distance, 

# The minimal number of insertions, deletions and substitutions needed to transform one string into another.
utils::adist(c("Johnson and Johnson"), c("Johnson & Johnson", "Johnson and Johnson")) 

# Base R string distance
# The distance is a generalized Levenshtein (edit) distance.
# Basically, the minimal number of insertions, deletions and substitutions needed to transform one string into another.
# In the example below, 3 edits are needed (1 replacement, 2 deletions)
utils::adist("Johnson and Johnson", "Johnson & Johnson") 

# Base R fuzzy match
# Two Johnson and Johnson and SC Johnson are different companies
# Return the indexs for any fuzzy matches
base::agrep("Johnson and Johnson", c("Johnson & Johnson", "SC Johnson"), max=3, ignore.case = TRUE)

# Richard Vogg getting annoyed, butilding a package to help
# https://twitter.com/richard_vogg/status/1354091535445467139
devtools::install_github("richardvogg/fuzzymatch")
dedupes <- fuzzymatch::fuzzy_dedupes(plastics$parent_company,find_cutoff=TRUE)

# Richard used Jaro-Winkler distance.  
stringdist("Johnson and Johnson", "Johnson & Johnson",method = "jw")

# This is basically just like Levenshtein, but it:
#  - weights the characters towards the begining of the string more
#  - sorts words in the same order in phrases
#  - Returns the difference as ratio between zero and one.

# All of the methods supported
# https://www.rdocumentation.org/packages/stringdist/versions/0.9.6.3/topics/stringdist-metrics

# There is a large number of algorithms to measure the "distance" between two strings.
http://users.cecs.anu.edu.au/~Peter.Christen/publications/tr-cs-06-02.pdf

# But it can get super complicated and requires algoritmic thinking
# https://github.com/dedupeio/dedupe
https://dedupe.io/documentation/how-it-works.html


plastics %>% filter(parent_company == "Grand Total")
plastics %>% filter(parent_company == "Argentina")


blacklist <- c("Grand Total", "Unbranded", "null", "NULL")
plastics %>% filter(!parent_company %in% blacklist) %>% group_by(parent_company) %>% summarise(company_total = sum(grand_total)) %>% arrange(desc(company_total))


