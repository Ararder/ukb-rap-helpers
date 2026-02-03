library(tidyverse)
library(fs)



df <- read_csv("category_138.csv") |> 
  rename_with(\(x) str_remove(x, "participant."))
meta_qc <- read_csv("qc_metadata.csv") |> 
  rename_with(\(x) str_remove(x, "participant."))

xx <- dir_ls(glob = "*f20002*") |> 
  map(\(x) {
    read_csv(x)
  }) |> 
  reduce(inner_join)

selfrep <- xx |> 
  rename_with(
    \(x) str_remove(x, "participant.p20002_i0_")
  ) |> 
  rename(eid = 1)

rm <- selfrep |> 
  pivot_longer(-eid) |> 
  filter(value %in% c(1408,1409,1410,1289,1291))


prob_bip <- read_csv("field_20126.csv") |> 
  filter(participant.p20126_i0 %in% c(1,2)) |> 
  rename(eid = 1)

rm <- bind_rows(rm, prob_bip) |> distinct(eid)


large_impact <- df |> 
  filter(p20440 == 3)


# cohort <- 
meta <- meta_qc |> 
  # used in PCA
  filter(p22020 == 1) |> 
  # white british
  filter(p22006 == 1) |> 
  # het missing outlier
  filter(is.na(p22027)) |> 
  # submitteed gender = genetic gender
  filter(p31 == p22001) |> 
  filter(is.na(p22019)) |> 
  anti_join(rm)
  # 334,315



# 157,130
has_mhq <- df |> 
  filter(!is.na(p20441) | !is.na(p20446))

# map 
names <- c(
  "A1" = "p20446",
  "A2" = "p20441",
  "A3" = "p20536",
  "A4" = "p20532",
  # "A5" = ""
  "A6" = "p20449",
  "A7" = "p20450",
  "A8" = "p20435",
  "A9" = "p20437"
)

wdf <- df |> 
  rename_with(\(x) str_remove(x, "participant.")) |> 
  select(eid, !!names) |> 
  semi_join(meta) |> 
  mutate(
    A3 = case_when(
      A3 %in% c(1,2,3) ~ 1,
      A3 == 0 ~ 0,
    )
  )




my_table <- map(colnames(wdf)[-1], \(x) count(wdf, !!sym(x))) |> 
  map(\(xx) {
    cname <- colnames(xx)[1]
    filter(xx, .data[[cname]] %in% c(0,1)) |> 
      mutate({{ cname }} := if_else(.data[[cname]] == "0", "no", "yes")) |> 
      rename(answer = 1) |> 
      pivot_wider(names_from = answer, values_from = n) |> 
      mutate(question = cname) |> 
      relocate(question, yes, no)
      
    
  }) |> 
  list_rbind()

# 16,184
cidi_sf_lifetime <- wdf |> 
  mutate(across(-1, \(x) if_else(x %in% c(-818, -121), NA_real_, x))) |> 
  mutate(total_score = rowSums(across(2:9), na.rm = TRUE)) |> 
  filter(total_score >= 5) |> 
  semi_join(large_impact) 

cases <- distinct(cidi_sf_lifetime, eid)
  

# good start - now current DEP


current_mdd <- c(
  "A1" = "p20510",
  "A2" = "p20514",
  "A3" = "p20511",
  "A4" = "p20517",
  "A5" = "p20518",
  "A6" = "p20519",
  "A7" = "p20507",
  "A8" = "p20508",
  "A9" = "p20513"
)




ll <- df |> 
  semi_join(meta) |> 
  select(eid,!!current_mdd)


current_symptom_count <- map(colnames(ll)[-1], \(x) count(ll, !!sym(x))) |> 
  map(\(xx) {
    cname <- colnames(xx)[1]
    filter(xx, .data[[cname]] %in% c(1,2,3,4)) |> 
      mutate({{ cname }} := if_else(.data[[cname]] == 4, "yes", "no")) |> 
      summarise(n = sum(n), .by = .data[[cname]]) |> 
      rename(answer = 1) |> 
      pivot_wider(names_from = answer, values_from = n) |> 
      mutate(question = cname) |> 
      relocate(question, yes, no)
    
    
  }) |> 
  list_rbind()

current <- 
  df |> 
  semi_join(meta) |> 
  select(eid,!!current_mdd) |> 
  filter(!is.na(A1) | !is.na(A2)) |> 
  mutate(across(-1, \(x) case_when(
    x == 4 ~ 1,
    x %in% c(3,2,1) ~ 0,
    .default = NA_real_))
    ) |> 
  mutate(
    tot_score = rowSums(across(-1), na.rm = TRUE)
  ) |> 
  mutate(
    current_case = if_else(
      tot_score >= 5 & eid %in% large_impact$eid,1,0
    )
  )
  


# 16,201
Lifetime_MDD <- bind_rows(current, cidi_sf_lifetime) |> 
  distinct(eid)


episode_count <- 
  df |> 
  select(eid, n_episodes = p20442) |> 
  semi_join(meta) |> 
  semi_join(has_mhq) |> 
  mutate(
    count_v1 = case_when(
      n_episodes == -818 ~ NA_real_,
      n_episodes >= 2 ~ 1,
      n_episodes == -999 ~ 1,
      n_episodes < 2 ~ 0,
      .default = 33
      
    )
  )



Lifetime_MDD |> 
  inner_join(select(df, eid, p20442)) |> 
  mutate(
    episodes = case_when(
      p20442 >= 2 ~ "2 or more, number given",
      p20442 == -999 ~"to many to count",
      p20442 == 1 ~ "1 episodes",
      p20442 == -818 ~ "Cant remember",
      p20442 < 1 ~ "less than 1 episode",
      
    )
  ) |> 
  filter(episodes != "1 episodes")
  semi_join(filter(episode_count, count_v1 == 1))











current <- rename_with(current, \(x) paste0("PHQ_", x), -eid)
cidi_sf_lifetime <- rename_with(cidi_sf_lifetime, \(x) paste0("lf_",x), -eid)
###
Lifetime_MDD |>
  left_join(cidi_sf_lifetime) |> 
  left_join(current) |> 
  mutate(
    lifetime_case = if_else(eid %in% cidi_sf_lifetime$eid,1,0),
    current_case = if_else(eid %in% current$eid,1,0),
    ) |> 
  summarise(
    across(2:9, \(x) mean(x, na.rm = TRUE))
  ) |> 
  pivot_longer(everything()) |> 
  ggplot(aes(y = value, x = name)) +
  geom_col() +
  scale_y_continuous(
    limits = c(0, 1),
    breaks = c(0, 0.2, 0.4, 0.6, 0.8, 1),
    labels = scales::percent
  ) +
  geom_hline(yintercept = 0.6) +
  theme_classic()


current_fig <- Lifetime_MDD |>
  left_join(cidi_sf_lifetime) |>
  left_join(current) |> 
  mutate(
    lifetime_case = if_else(eid %in% cidi_sf_lifetime$eid,1,0),
    current_case = if_else(eid %in% current$eid,1,0),
  ) |> 
  select(-c(2:10)) |> 
  summarise(
    across(2:10, \(x) mean(x, na.rm = TRUE))
  ) |> 
  pivot_longer(everything()) |> 
  ggplot(aes(y = value, x = name)) +
  geom_col() +
  theme_classic()



current |> 
  rename(total_score = tot_score) |> 
  count(total_score) |> 
  ggplot(aes(x = factor(total_score), y = n)) +
  geom_col()




# 


wdf |> 
  count(A1, A2)
  filter(A1 == 1 | A2 == 1) 

  
df |> 
  select(p20441, p20446, p20510, p20514) |> 
  filter(if_any(everything(), \(x) x == 1))


total_cohort <- df |> 
  filter(!is.na(p20441) | !is.na(p20446)) |> 
  semi_join(meta)


xx <- wdf |> 
  filter(!is.na(A1) | !is.na(A2)) |> 
  drop_na()


bind_rows(xx, cidi_sf_lifetime) |> distinct()



wdf |> 
  filter(!is.na(A1) | !is.na(A2)) |> 
  anti_join(cidi_sf_lifetime, by = "eid")
  mutate(across(-1, \(x) if_else(x %in% c(-818, -121), NA_real_, x))) |> 
  mutate(total_score = rowSums(across(2:9), na.rm = TRUE)) |> 
  count(total_score)


select(df, eid, p20442) |> 
  filter(!is.na(p20442)) |> 
  mutate(new_var = if_else(p20442 >= 2, 2, p20442)) |> 
  count(new_var)

wdf |> 
  semi_join(cidi_sf_lifetime, by = "eid")
  filter(!is.na(A1) & !is.na(A2)) |> 
  semi_join(cidi_sf_lifetime)

  
cases |> 
  inner_join(select(df, eid, p20442), by = "eid") |> 
  mutate(more_than_2 = if_else(p20442 >= 2 | p20442 == -999,1,0)) |> 
  count(more_than_2)

  
  
  
df |> 
  # filter(p20442 >= 2) |> 
  semi_join(meta) |> 
  select(eid, !!names) |> 
  mutate(
    A3 = case_when(
      A3 %in% c(1,2,3) ~ 1,
      A3 == 0 ~ 0,
    )
  ) |> 
  mutate(across(2:9, \(x) if_else(!x %in% c(0,1), NA_real_, x))) |> 
  mutate(
    score = rowSums(across(2:9), na.rm = TRUE)
  ) |> 
  filter(score >= 5) |> 
  semi_join(large_impact)
  

  


base_cohort <- df |> 
  semi_join(meta) |> 
  filter(!is.na(p20440) | !is.na(p20446))



no_cases <- base_cohort |> 
  anti_join(cidi_sf_lifetime)


no_cases |> 
  count(p20440)






mhq <- df |> 
  filter(!is.na(p20440) | !is.na(p20446))




# 67K individuals without any depression indication.
mhq |>
  anti_join(rm) |> 
  filter(p20441 == 0 & p20446 == 0) |> 
  inner_join(meta_qc) |> 
  filter(p22020 == 1) |> 
  filter(p22006 == 1) |> 
  filter(is.na(p22027)) |> 
  filter(p31 == p22001) |> 
  filter(is.na(p22019))
  



# 45k controls
mhq |> 
  semi_join(meta) |> 
  filter(p20441 == 1 | p20446 == 1) |> 
  anti_join(cidi_sf_lifetime)







# attempt at finding control set


wdf <- df |> 
  rename_with(\(x) str_remove(x, "participant.")) |> 
  select(eid, !!names) |> 
  semi_join(meta) |> 
  mutate(
    A3 = case_when(
      A3 %in% c(1,2,3) ~ 1,
      A3 == 0 ~ 0,
    )
  ) |> 
  filter(!is.na(A1) | !is.na(A2))


# 109,578
lifetime <- wdf |> 
  inner_join(select(df,eid, p20440)) |>
  mutate(across(2:9, \(x) if_else(x %in% c(1,0),x, NA_real_))) |> 
  mutate(
    tot_score = rowSums(across(2:9), na.rm =T)
  ) |> 
  filter(tot_score >= 5) |> 
  filter(p20440 == 3)
  # count(tot_score)



# What is a control?
# 1) has to have answered MHQ
# 2) in genotyped cohort
# 3) 
wdf |> 
  mutate(answered_mhq = eid %in% lifetime$eid) |> 
  mutate(
    atleast_1_endorse = case_when(
      eid %in% lifetime$eid ~ 1,
      !eid %in% lifetime$eid & A1 == 1 | A2  ~  0,
      .default = NA_real_
    )) |> 
  count(atleast_1_endorse)
  
  inner_join(select(df,eid, p20440))


  
  
## get assesment center
bristol <- 11011
center <- read_csv("field_54.csv")


bristol_participants <- center |> 
  rename(eid = 1) |> 
  semi_join(meta) |> 
  # count(participant.p54_i0) |> 
  # mutate(pct = n / sum(n)) |> 
  filter(participant.p54_i0 == bristol)


# 1613/5047 
# recurrent: 1001/4880 

# i'm off by 9 individuals for cases
wdf |> 
  semi_join(bristol_participants) |> 
  semi_join(Lifetime_MDD)

# now for controls

# theory 1: controls have answered some variation of atleast 1 symptom
wdf |> 
  filter(A1 == 1 | A2 == 1) |> 
  anti_join(cidi_sf_lifetime) |> 
  semi_join(bristol_participants)


# off by 11%
(50870 - 45211) / 50870

# off by 8.2%
(5047 - 4630) / 5047


# theory 2
# cases are excluded based on impact

ctrl_t1 <- 
  wdf |> 
  inner_join(select(df, eid, p20440)) |> 
  anti_join(cidi_sf_lifetime) |> 
  filter(!p20440 %in% c(0,1,2,-818))
  
  inner_join(select(df, eid, p20442)) |> 
  mutate(
    episodes = case_when(
      p20442 >= 2 ~ "2 or more, number given",
      p20442 == -999 ~"to many to count",
      p20442 == 1 ~ "1 episodes",
      p20442 == -818 ~ "Cant remember",
      p20442 < 1 ~ "less than 1 episode",
      
    )
  )



ctrl_t2 <- wdf |> 
  inner_join(select(df, eid, p20440)) |> 
  anti_join(cidi_sf_lifetime) |> 
  filter(A1 == 1 | A2 == 1) |> 
  inner_join(select(df, eid, p20442)) |> 
  mutate(
    episodes = case_when(
      p20442 >= 2 ~ "2 or more, number given",
      p20442 == -999 ~"to many to count",
      p20442 == 1 ~ "1 episodes",
      p20442 == -818 ~ "Cant remember",
      p20442 < 1 ~ "less than 1 episode",
      
    )
  )




ctrl_t2 |> count(episodes)
ctrl_t1 |> count(episodes)


select(df, eid, p20442) |> 
  semi_join(wdf) |> 
  filter(!is.na(p20442)) |> 
  anti_join(cidi_sf_lifetime) |> 
  count(p20442)




wdf |> 
  anti_join(Lifetime_MDD) |> 
  inner_join(select(df, eid, p20442)) |> 
  inner_join(select(df, eid, p20440)) |> 
  filter(!p20440 %in% c(0,1,2, -818)) |> 
  count(p20440)
  filter(!p20442 %in% c(-818, 1))
  