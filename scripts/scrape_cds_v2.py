# Import packages

from requests import get
from bs4 import BeautifulSoup

from time import sleep
import os

import numpy as np
import pandas as pd

# Set working directory

wd = "C:\\Users\\Daniel\\Google Drive\\Projects\\2020.01 Yale's Most Popular Courses\\raw-data2"
os.chdir(wd)

# Set parameters

semester = '202001' # semester code (examples: 202001 = 2020 Spring, 201903 = 2019 Fall)

# Get list of subjects

def getSubjects():
    url = 'https://ivy.yale.edu/course-stats/'
    r = get(url)
    s = BeautifulSoup(r.text, 'html.parser')

    subjects_elems = s.select('#subjectCode option')
    subjects_codes = [elem.text.split(" - ", 2)[0] for elem in subjects_elems[1:]]
    subjects_names = [elem.text.split(" - ", 2)[1] for elem in subjects_elems[1:]]

    pd.DataFrame({
        'subject': subjects_codes, 
        'name': subjects_names
    }).to_csv('subjects.csv', index=False)

    return subjects_codes

subjects = getSubjects()

# Get list of dates

def getDates(sem):
    url = 'https://ivy.yale.edu/course-stats/?termCode=' + sem + '&subjectCode=AMTH'
    r = get(url)
    s = BeautifulSoup(r.text, 'html.parser')

    dates_table = s.select("table table")[0].select("td")
    
    return [entry.text.strip() for entry in dates_table]

dates_headers = getDates(semester)

courses_ids = []
courses_codes = []
courses_names = []

demand_ids = []
demand_codes = []
demand_dates = []
demand_counts = []

i = 1

for subject in subjects:
    url = 'https://ivy.yale.edu/course-stats/?termCode=' + semester + '&subjectCode=' + subject.replace("&", "%26")
    r = get(url)
    s = BeautifulSoup(r.text, 'html.parser')

    courses = s.select("div#content > div > table > tbody > tr")

    for course in courses:
        code = course.select("td a")[0].text.strip().replace(";", "")
        name = course.select("td span")[0].text.strip().replace(";", "")

        full_strings_all = code.split("/")
        full_strings = [string for string in full_strings_all if string.split(" ")[0] in subjects]
        code_this_subject = [string for string in full_strings if subject in string][0]

        if full_strings.index(code_this_subject) == 0:
            for string in full_strings:
                courses_ids.append(i)
                courses_codes.append(string)
                courses_names.append(name)

            demands_containers = course.select("td.trendCell")

            for j in range(len(dates_headers)):
                demand_ids.append(i)
                demand_codes.append(code_this_subject)
                demand_dates.append(dates_headers[j])
                demand_counts.append(demands_containers[j].text.strip())
        
        i += 1


df_courses = pd.DataFrame({'id': courses_ids, 
                           'code': courses_codes, 
                           'name': courses_names})
df_demand = pd.DataFrame({'id': demand_ids,
                          'date': demand_dates,
                          'count': demand_counts})

df_courses.to_csv('courses.csv', index = False)
df_demand.to_csv('demand.csv', index = False)