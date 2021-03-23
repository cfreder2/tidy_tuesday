# 14 participants

# https://github.com/rfordatascience/tidytuesday/blob/master/data/2021/2021-02-02/readme.md

library("tidyverse")
library("janitor")
library("devtools")
library("stringdist")
library("tidytuesdayR")
tuesdata <- tidytuesdayR::tt_load('2021-02-02')

hs_students <- tuesdata$hs_students
