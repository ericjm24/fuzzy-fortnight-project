import requests
import csv

cit_file = "data/uscities.csv"
cities = []
with open(cit_file, "r") as f:
    k = 0
    for line in f:
        if k == 0:
            k=1
            continue
        
        row = [x.replace('\"', '') for x in line.split(',')]
        try:
            temp = {
                'name':row[0],
                'state':row[2],
                'longitude':float(row[8]),
                'latitude':float(row[9]),
                'population':int(round(float(row[10]))),
                'density':float(row[11])
            }
            cities.append(temp)
        except:
            temp = {
                'name':', '.join(row[0:2]),
                'state':row[4],
                'longitude':row[10],
                'latitude':row[11],
                'population':int(round(float(row[12]))),
                'density':float(row[13])
            }
            cities.append(temp)

city_names = {}
for c in cities:
    if c['name'] in city_names.keys():
        city_names[c['name']].append(c)
    else:
        city_names[c['name']] = [c]

abbr_to_states = {
        'AK': 'Alaska',
        'AL': 'Alabama',
        'AR': 'Arkansas',
        'AZ': 'Arizona',
        'CA': 'California',
        'CO': 'Colorado',
        'CT': 'Connecticut',
        'DC': 'District of Columbia',
        'DE': 'Delaware',
        'FL': 'Florida',
        'GA': 'Georgia',
        'HI': 'Hawaii',
        'IA': 'Iowa',
        'ID': 'Idaho',
        'IL': 'Illinois',
        'IN': 'Indiana',
        'KS': 'Kansas',
        'KY': 'Kentucky',
        'LA': 'Louisiana',
        'MA': 'Massachusetts',
        'MD': 'Maryland',
        'ME': 'Maine',
        'MI': 'Michigan',
        'MN': 'Minnesota',
        'MO': 'Missouri',
        'MS': 'Mississippi',
        'MT': 'Montana',
        'NC': 'North Carolina',
        'ND': 'North Dakota',
        'NE': 'Nebraska',
        'NH': 'New Hampshire',
        'NJ': 'New Jersey',
        'NM': 'New Mexico',
        'NV': 'Nevada',
        'NY': 'New York',
        'OH': 'Ohio',
        'OK': 'Oklahoma',
        'OR': 'Oregon',
        'PA': 'Pennsylvania',
        'RI': 'Rhode Island',
        'SC': 'South Carolina',
        'SD': 'South Dakota',
        'TN': 'Tennessee',
        'TX': 'Texas',
        'UT': 'Utah',
        'VA': 'Virginia',
        'VI': 'Virgin Islands',
        'VT': 'Vermont',
        'WA': 'Washington',
        'WI': 'Wisconsin',
        'WV': 'West Virginia',
        'WY': 'Wyoming'
}

state_to_abbr = {v.upper():k for k,v in abbr_to_states.items()}

class census():
    def __init__(self, api_key):
        self.api_key = api_key

    def get_FIPS_from_coord(self, coord, benchmark = 9, vintage=910):
        url = "https://geocoding.geo.census.gov/geocoder/geographies/coordinates?"
        url += f"x={coord[0]}&y={coord[1]}"
        url += f"&benchmark={benchmark}"
        url += f"&vintage={vintage}"
        url += "&format=json"
        response = requests.get(url)
        if response.status_code == 200:
            dat = response.json()["result"]["geographies"]
            #print(dat)
            out = {
                'state':dat["States"][0]['STATE'],
                'county':dat["Counties"][0]['COUNTY'],
                'tract':dat["Census Tracts"][0]['TRACT'],
                'block':dat["Census Blocks"][0]['BLOCK']
            }
        else:
            out = {}
        return out

    def get_population_from_coord(self, coord):
        addr = self.get_FIPS_from_coord(coord)
        url = "https://api.census.gov/data/2012/acs/acs5/profile?get=NAME,B00001_001E&for="
        url += f"tract:{addr['tract']}"
        url += f"&in=county:{addr['county']}%20state:{addr['state']}"
        url += f"&key={self.api_key}"
        response = requests.get(url)
        if response.status_code == 200:
            return response.json()

    def get_data_from_FIPS(self, addr, year=2010, data_names={}):
        url = "https://api.census.gov/data/"
        url += str(int(year)) + "/acs/acs5/profile?get=NAME"
        for s in data_names.keys():
            url += ',' + s
        url += f"&for=tract:{addr['tract']}"
        url += f"&in=county:{addr['county']}%20state:{addr['state']}"
        url += f"&key={self.api_key}"
        response=requests.get(url)
        if response.status_code == 200:
            dat = response.json()
            outDict = {}
            for t in range(len(dat[0])):
                if dat[0][t] in list(data_names.keys()):
                    outDict[data_names[dat[0][t]]] = dat[1][t]
                else:
                    outDict[dat[0][t]] = dat[1][t]
            return outDict
        return None

    def get_tract_data_for_state(self, state='CA', year=2010, data_names={}):
        url = url = "https://api.census.gov/data/"
        url += str(int(year)) + "/acs/acs5/profile?get=NAME"
        for s in data_names.keys():
            url += ',' + s
        url += "&for=tract:*"
        url += f"&in=state:{codes[state]}"
        url += f"&key={self.api_key}"
        response=requests.get(url)
        if response.status_code == 200:
            dat = response.json()
            return dat
            outDict = {}
            for t in range(len(dat[0])):
                if dat[0][t] in list(data_names.keys()):
                    outDict[data_names[dat[0][t]]] = dat[1][t]
                else:
                    outDict[dat[0][t]] = dat[1][t]
            return outDict
        return None

    def get_place_data_all(self, year=2010, data_names={}):
        url = url = "https://api.census.gov/data/"
        url += str(int(year)) + "/acs/acs5/profile?get=NAME"
        for s in data_names.keys():
            url += ',' + s
        url += "&for=place:*&in=state:*"
        url += f"&key={self.api_key}"
        response=requests.get(url)
        if response.status_code == 200:
            dat = response.json()
            return dat
            outDict = {}
            for t in range(len(dat[0])):
                if dat[0][t] in list(data_names.keys()):
                    outDict[data_names[dat[0][t]]] = dat[1][t]
                else:
                    outDict[dat[0][t]] = dat[1][t]
            return outDict
        return None

    def get_data_from_coord(self, coord, year = 2010, data_names={}):
        addr = self.get_FIPS_from_coord(coord)
        return self.get_data_from_FIPS(addr, year, data_names)

    def get_data_all_years_from_coord(self, coord, data_names={}):
        addr = self.get_FIPS_from_coord(coord)
        dat = {2010:self.get_data_from_FIPS(addr, 2010, data_names)}
        for year in range(2010,2018):
            temp = self.get_data_from_FIPS(addr, year, data_names)
            dat[year] = temp
        return dat

    def get_data_spline_from_coord(self, coord, data_names):
        dat = self.get_data_all_years_from_coord(coord, data_names)
        out = dat[2010]
        for t in data_names.values():
            x = range(2010, 2018)
            y = [dat[z][t] for z in x]
            try:
                out[t] = PchipInterpolator(x,y)
            except ValueError:
                out[t] = None
        return out
