#!/usr/bin/env python3

import os
import io
import glob
import datetime

import numpy as np
import scipy.io
import boto3
import tqdm


def extract(filename, fd):
    # remove extension and _ that some files have
    parsed_filename = os.path.splitext(filename)[0].split('_')[0]

    # parse the file and date? from the filename
    flight = parsed_filename[:-12]
    timestamp = datetime.datetime.strptime(parsed_filename[-12:], '%Y%m%d%H%M')

    # parse the .mat file
    data = scipy.io.loadmat(fd, simplify_cells=True)

    # remove all metadata and keep only values
    data = {k: v['data'] for k, v in data.items() if not k.startswith('__')}

    return (flight, timestamp, data)


def extract_all(s3_objects, export_path):
    num_total = 0
    num_valid = 0
    num_start_errors = 0
    num_end_errors = 0
    num_less_swap_errors = 0
    num_more_swap_errors = 0

    for s3_object in tqdm.tqdm(list(s3_objects)):
        filename = os.path.basename(s3_object.key)

        with io.BytesIO() as fd:
            s3_object.Object().download_fileobj(fd)
            flight, timestamp, data = extract(filename, fd)

        num_total += 1
        if data['LGDN'][0]== 1:
            #print(f'Dropping {path} because LGDN starts at 1')
            num_start_errors += 1
            continue
        if data['LGDN'][-1]== 1:
            #print(f'Dropping {path} because LGDN ends at 1')
            num_end_errors += 1
            continue
        lgdn_diff = np.ediff1d(data['LGDN'])
        lgdn_swaps = len(lgdn_diff[np.nonzero(lgdn_diff)])
        if lgdn_swaps < 2:
            #print(f'Dropping {path} because LGDN changes less than twice')
            num_less_swap_errors += 1
            continue
        if lgdn_swaps > 2:
            #print(f'Dropping {path} because LGDN changes more than twice')
            num_more_swap_errors += 1
            continue
        num_valid += 1

        path = os.path.join(export_path, flight, os.path.splitext(filename)[0])
        os.makedirs(os.path.dirname(path), exist_ok=True)
        np.savez_compressed(path, **data)

    print(f'processed: {num_total} \
            valid: {num_valid} \
            bad start: {num_start_errors} \
            bad end: {num_end_errors} \
            less swaps: {num_less_swap_errors} \
            more swaps: {num_more_swap_errors}')


if __name__ == '__main__':
    s3 = boto3.resource('s3')
    bucket = s3.Bucket('iia-vault-telemetry-practice-unzipped')

    extract_all(bucket.objects.filter(Prefix='Flight 652'), 'data')
