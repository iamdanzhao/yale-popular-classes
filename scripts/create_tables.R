require(readr)
require(dplyr)
require(stringr)
require(tidyr)

setwd("C:/Users/Daniel/Google Drive/Projects/2020.01 Yale's Most Popular Courses/scripts")

# helper functions

unite_code <- function(df) {
	unite(df, code, subject, number, sep = " ", remove = FALSE)
}

separate_code <- function(df) {
	separate(df, code, into = c("subject", "number"), sep = " ", remove = FALSE)
}

separate_designator <- function(df) {
	df %>%
		mutate(number = as.numeric(str_extract(number, "[[:digit:]]+")),
			   designator = str_extract(number, "[:alpha:]"))
}

# read in data

demand <- read_csv("../raw-data/demand.csv") %>%
	mutate(date = as.Date(date, format = "%m/%d"))

courses <- read_csv("../raw-data/courses.csv") %>%
	separate_code() %>%
	separate_designator() %>%
	select(id, code, subject, number, designator, name)

coursetable <- read_csv("../raw-data/coursetable.csv") %>%
	unite_code() %>%
	separate_designator() %>%
	select(code, subject, number, designator, section, times, locations, rating, workload)

# GENERATE TABLE: TOP COURSES

top_ids <- demand %>%
	filter(date == max(date)) %>%
	arrange(desc(count)) %>%
	top_n(10)

top_names <- courses %>%
	filter(id %in% top_ids$id) %>%
	group_by(id) %>%
	summarize(name = first(name),
			  codes = paste(code, collapse = " / "))

top_courses <- top_ids %>%
	left_join(top_names)

write_csv(top_courses, "../data/most_shopped.csv")

# GENERATE TABLE: TRENDING

trending_ids <- demand %>%
	filter(date == max(date) | date == max(date) - 1) %>%
	spread(date, count) %>%
	`colnames<-`(c("id", "yesterday", "today")) %>%
	filter(yesterday >= 3) %>%
	mutate(change = today - yesterday,
		   absChange = abs(change),
		   pctChange = change / yesterday) %>%
	arrange(desc(absChange)) %>%
	select(id, yesterday, today, change, absChange) %>%
	top_n(20)

trending_names <- courses %>%
	filter(number < 500) %>%
	filter(id %in% trending_ids$id) %>%
	group_by(id) %>%
	summarize(name = first(name),
			  codes = paste(code, collapse = " / "))

trending <- trending_ids %>%
	left_join(trending_names) %>%
	filter(!is.na(codes)) %>%
	top_n(10)

write_csv(trending, "../data/trending.csv")

# GENERATE TABLE: SEMINARS

seminars <- coursetable %>%
	# get rid of the 1 HTBAs
	filter(times != "1 HTBA") %>%
	# get the first "word" in the string of times
	mutate(word = stringr::word(times)) %>%
	# the first word must be one letter long (M, T, W, F) or "Th"
	filter(str_length(word) == 1 | word == "Th") %>%
	left_join(demand %>%
			  	filter(date == max(date)) %>%
			  	left_join(courses)) %>%
	# undergrad courses only
	filter(number < 500) %>%
	# these were a lab and Corp Finance (that for some reason only met one a week)
	filter(!(id %in% c(655, 1784))) %>%
	select(code, id, count, name, times) %>%
	group_by(id) %>%
	summarize(name = first(name),
			  codes = paste(code, collapse = " / "),
			  count = first(count),
			  times = first(times)) %>%
	arrange(desc(count)) %>%
	top_n(10, count)

write_csv(seminars, "../data/seminars.csv")
