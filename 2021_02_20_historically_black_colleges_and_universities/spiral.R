library(tidyverse)

# pair of parametric equations

# build a dataset of line segements for the spiral
spiral <- tibble(theta = seq(10,40,by=.1), # a larger number of line segements to make the spiral smooth (try .5 vs .1)
                 x = theta * sin(theta),
                 y = theta * cos(theta))


# draw it
spiral %>% ggplot(aes(x=x,y=y)) + geom_path(color="red") + coord_fixed(ratio = 1)
