import pickle
import pandas as pd
import numpy as np
import csv
import matplotlib as mp
import matplotlib.pyplot as plt
from numpy.lib import recfunctions
import datetime
import numpy.lib.recfunctions as recfn
import boto3
import sys
from IPython.display import clear_output
from scipy import stats, fftpack
from scipy.stats import kurtosis, skew, iqr, t
import pickle
from scipy import io as sio
s3 = boto3.resource('s3')
from io import BytesIO
from sklearn.preprocessing import MinMaxScaler, StandardScaler

def s3_bucket_object_keys(bucket_name= IN_BKT):
    bucket = s3.Bucket(bucket_name)
    key_list=[]
    for key in bucket.objects.all():
        key_list.append(key)
    sorted(key_list, key = lambda x: int(x.key[16:28]))
    return(key_list)
