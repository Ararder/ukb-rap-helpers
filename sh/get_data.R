library(tidyverse)

fields <- read_tsv("field.txt")
arg <- commandArgs(trailingOnly = TRUE)[1]
sel_fields <- filter(fields,main_category == arg)
write_tsv(select(sel_fields,field_id),"selected_fields.txt", col_names = FALSE)






