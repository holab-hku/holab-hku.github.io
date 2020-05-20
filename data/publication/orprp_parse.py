from bs4 import BeautifulSoup
import csv

items = []
html_doc = ""
with open ("orprp.html", "r") as f:
    html_doc = f.read()

soup = BeautifulSoup(html_doc, 'html.parser')

li_items = soup.find_all("li")
for li in li_items:
    # authors = 
    author_bold = " ".join(li.find("strong").text.split())
    authors = " ".join(li.text.split(" (")[0].split())
    year = li.text.split(" (")[1].split(")")[0]

    paper_url = li.find("a").get("href")
    paper_name = " ".join(li.find("a").text.split())

    journal = " ".join(li.find("em").text.split())

    remaining1 = li.find("em").parent.next_sibling
    remaining2 = li.find_all("strong")[1].parent.next_sibling 
    remaining = str(remaining1) + str(remaining2)

    all_as = li.find_all("a")
    if len(all_as) > 1:
        remaining += str(all_as[1])
    print(remaining.replace("\n", ""))

    item = {
        "authors": authors,
        "author_bold": author_bold,
        "year": year,
        "paper_url": paper_url,
        "paper_name": paper_name,
        "journal": journal,
        "remaining": remaining
    }
    items.append(item)
    # print(journal)
    # print( author_bold, "|", authors)
    # print(author_bold in authors)
    # print(li.text.strip())
    # print(paper_name)
    # print(paper_url)
    # print(year)
    print()
    # print(li.prettify())
# print(soup.prettify())

with open('orprp.csv', 'w', newline='') as csvfile:
    fieldnames = ["authors", "author_bold", "year", "paper_url", "paper_name", "journal", "remaining"]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

    writer.writeheader()
    for item in items:
        writer.writerow(item)