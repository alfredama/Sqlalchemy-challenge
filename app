#importing dependencies 
import numpy as np

import sqlalchemy
from sqlalchemy.ext.automap import automap_base
from sqlalchemy.orm import Session
from sqlalchemy import create_engine, func
import datetime as dt
from flask import Flask, jsonify

#database setup##
engine = create_engine("sqlite:///Resources/hawaii.sqlite")
#reflect the exisiting database 
Base = automap_base()

#reflecting tables
Base.prepare(engine, reflect=True)

# Save references to each table
Measure = Base.classes.measurement
Station = Base.classes.station


#flask setup
app = Flask(__name__)

#Begin flask routes
@app.route("/")
def welcome():
   
    return (
        f"Available Routes:<br/>"
        f"/api/v1.0/precipitation HT returns all dates and coreesponfing preciptitation in the data base <br/>"
        f"/api/v1.0/stations returns all stations in the station table<br/>"
        f"/api/v1.0/tobs   returns all temperatures observed in the station from one year back table<br/>"
        f"/api/v1.0/<start> returns min temperature , avg temperature and max temperature over a defined start time .for ex /api/v1.0/2015-06-15 <br/>"
        f"/api/v1.0/<start>/<end> returns min temperature , avg temperature and max temperature over a defined start time .for ex /api/v1.0/2015-06-15/2017-10-15<br/>"
    )

@app.route("/api/v1.0/precipitation")
def precip():
    #stating connection from python to DB   
    session = Session(engine)
    results = session.query(Measure.date, Measure.prcp).all()
    session.close()
    
    #moving results to dictionary
    all_Precip = []
    for date, prcp in results:
        each_precip = {}
        each_precip["Date"] = date
        each_precip["Precipitation"] = prcp
        all_Precip.append(each_precip)
        
    #returning JSON result to get request 
    return jsonify(all_Precip)

@app.route("/api/v1.0/stations")
def statn():

    #stating connection from python to DB   
    session = Session(engine)
    results = session.query(Station.name).all()
    session.close()
    
    #formatting tuple to list 
    all_stations = list(np.ravel(results))
    
    #returning JSON result to get request
    return jsonify(all_stations)
    
@app.route("/api/v1.0/tobs")
def tobz():

    #stating connection from python to DB   
    session = Session(engine)
    #creating query 
    station = session.query(Measure.station, func.count(Measure.station)).group_by(Measure.station).\
        order_by(func.count(Measure.station).desc()).all()

    station_name = station[0][0]

    #pulling data from session
    fartherst_date = session.query(Measure.date).filter(Measure.station == 'USC00519281').order_by(Measure.date.desc()).first()

    #calculating latest date in the data farme 
    latest_date = fartherst_date[0]
    one_year_back = dt.datetime.strptime(latest_date, '%Y-%m-%d') - dt.timedelta(days=365)
    results = session.query(Measure.date, Measure.tobs).filter(Measure.station == station_name).\
                    filter(Measure.date > one_year_back).all()
    session.close()
    
    #moving results to dictionary
    all_tobz = []
    for date, tobs in results:
        each_tobz = {}
        each_tobz["Date"] = date
        each_tobz["temperature observation"] = tobs
        all_tobz.append(each_tobz)
  
    #returning JSON result to get request
    return jsonify(all_tobz)
 
@app.route("/api/v1.0/<start>")
def startdate(start):

    #stating connection from python to DB   
    session = Session(engine)
    results = session.query(func.min(Measure.tobs), func.avg(Measure.tobs),func.max(Measure.tobs)).\
                filter(Measure.date > start).all()

    session.close()
    
    #formatting tuple to list 
    analysis = list(np.ravel(results))
    
    #returning JSON result to get request
    return jsonify(analysis)
 
@app.route("/api/v1.0/<start>/<end>") 
def enddate(start,end):

    #stating connection from python to DB   
    session = Session(engine)
    results = session.query(func.min(Measure.tobs), func.avg(Measure.tobs),func.max(Measure.tobs)).\
              filter(Measure.date > start).filter(Measure.date < end).all()

    session.close()
    
    #formatting tuple to list 
    analysis = list(np.ravel(results))
    
    #returning JSON result to get request
    return jsonify(analysis)
    
if __name__ == '__main__':
    app.run(debug=True)
   
    