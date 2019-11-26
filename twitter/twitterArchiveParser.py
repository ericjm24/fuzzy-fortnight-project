"""
Twitter Archive Parser
v 0.0.1
Created by: ericjm24
Nov 2019

This module parses the archived data from the archive.org twitter stream.
These archives come in the form of .tar files, each containing one .bz2 file for every
minute of the day.
"""

import os
from threading import Thread
import bz2
import json
from queue import Queue, Empty
import csv

class SafeWriter:
    """
    This class borrowed from stackoverflow user Leonid Mednikov with minor modifications by me.
    Modifications include the creation of a writerow function, as well as handling of null values.
    Taken from his answer in:
        https://stackoverflow.com/questions/30135091/write-thread-safe-to-file-in-python
    Written on:
        July 1, 2017

    It provides a thread-safe file writer.
    """
    def __init__(self, *args, **kwargs):
        self.filewriter = open(*args, **kwargs)
        self.queue = Queue()
        self.finished = False
        Thread(name = "SafeWriter", target=self.internal_writer).start()

    def write(self, data):
        if data:
            self.queue.put(str(data) + '\n')

    def writerow(self, data, delimiter=','):
        if type(data) == str:
            self.write(data)
        else:
            outstr = ''
            for k in data:
                if not k and k!=0:
                    temp = ''
                else:
                    temp = str(k)
                if temp.count(delimiter) >=1 and temp[0] != '\"':
                    temp = '\"' + temp + '\"'
                outstr += temp + delimiter
            self.write(outstr)


    def internal_writer(self):
        while not self.finished:
            try:
                data = self.queue.get(True, 1)
            except Empty:
                continue
            self.filewriter.write(data)
            self.queue.task_done()

    def close(self):
        self.queue.join()
        self.finished = True
        self.filewriter.close()


class twitterArchiveParser():
    """
    Class to parse the data from the Twitter stream saved on archive.org.
    This data is the Spritzer stream of Twitter, containing 1% of all public tweets.
    Find more on archive.org by searching for twitter stream, or read about the stream
    on the Twitter API documentation.

    Tweets are represented as json objects. Archive.org wraps each individual minute of
    tweets into a .bz2 file, then bundles them into entire months stored as a .tar file.
    To use this package, extract the .tar file to a working directory, but
    do not decompress the individual .bz2 files.

    Due to the large quantity of data, this class implements the threading package
    to provide a speed boost through parallel processing. To enable multi-threading,
    supply a non-zero num_threads argument. When multi-threading is enabled, order of
    tweets will not be maintained.

    To-Do:
        - Add functionality to work with .tar files directly
    """

    def __init__(self, archive_location, save_location, num_threads=0, verbose=False):
        """
        Description:
            init method for the twitterArchiveParser class.

        Arguments:
            archive_location - Path to the directory of the un-tarred archive

            save_location - Name of file to save the output to

            num_threads - number of parallel threads to use to process bz2 files.
                When num_threads is greater than zero, the writing of the output
                to a file will exist in its own additional thread, so the true
                number of threads being used is num_threads + 1

            verbose - if True, will output additional information relating to process completion
        """
        from math import ceil
        self._num_threads = ceil(num_threads)
        self.archive_location = archive_location
        self.save_location = save_location
        self.file_list = []
        self._verbose = verbose
        try:
            for (root, dirs, file) in os.walk(self.archive_location):
                if file:
                    for f in file:
                        self.file_list.append(os.path.join(root, f))
        except:
            print("Warning: File list not loaded from supplied directory. Use .load_file_directory() and make sure the path is specified correctly.")

    def load_file_directory(self, archive_location):
        """
        Description:
            Helper function to let the user load a new directory.

        Arguments:
            archive_location - Path to the directory of the un-tarred archive
        """
        try:
            for (root, dirs, file) in os.walk(archive_location):
                if file:
                    for f in file:
                        self.file_list.append(os.path.join(root, f))
        except:
            print("Warning: File list not loaded from supplied directory.")

    def _split_files_multi(self):
        """
        Description:
            Helper function to convert complete list of .bz2 functions into a set of lists
            used for multi-threading.

        Arguments:
            none
        """
        self._num_threads
        if self._num_threads < 2:
            return [self.file_list]
        else:
            split_list = [self.file_list[j::self._num_threads] for j in range(self._num_threads)]
            return split_list

    def parse_archive_minute(self, func, tweet_file, save_file, *args):
        """
        Description:
            Function that parses one whole minute (one .bz2 file) of the Twitter stream.
            Called by parse_archive.

        Arguments:
            func - User-supplied function to operate on each tweet.
                Should return either a string or an iterable
                Tweets are json objects and can be accessed like dictionaries in python

            tweet_file - One .bz2 file containing a single tweet as a json object per line.

            save_file - file writer object to save to. Can be either a csv.writer or SafeWriter
        """
        if '.bz2' not in tweet_file:
            return
        with bz2.open(tweet_file, mode="rt") as f:
            for tweet in f:
                ob = json.loads(tweet)
                if ob:
                    temp = func(ob,*args)
                    if temp:
                        save_file.writerow(temp)

    def _parse_archive_minute_list(self, func, f_list, save_file, *args):
        """
        Description:
            Helper function to iterate over a list of .bz2 files in a single thread.
            Calls parse_minute

        Arguments:
            func - see parse_minute

            f_list - list of .bz2 tweet archive files

            save_file - see parse_minute()
        """
        for tweet_file in f_list:
            self.parse_archive_minute(func, tweet_file, save_file, *args)
            if self._verbose:
                print("Finished file " + tweet_file)
        print("Thread finished\n")

    def parse_archive(self, func, *args):
        """
        Description:
            Function to run over an entire list of .bz2 files and write the output to
            the file location specified in the save_location property of the class instance.
            Utilizes multi-threading if enabled. Multi-threading is disabled by default.

        Arguments:
            func - User-supplied function to operate on each tweet.
                Should return either a string or an iterable
                Tweets are json objects and can be accessed like dictionaries in python
        """
        if self._num_threads < 1:
            save_file = open(self.save_location, "a", encoding='utf-8')
            writer = csv.writer(save_file, delimiter=',')

            self._parse_archive_minute_list(func, self.file_list, writer, *args)
        else:
            save_file = SafeWriter(self.save_location, "a", encoding='utf-8')
            f_lists = self._split_files_multi()
            thr_list = []
            for f_list in f_lists:
                temp = Thread(target=self._parse_archive_minute_list, args = (func, f_list, save_file, *args))
                thr_list.append(temp)
                temp.start()
            for thr in thr_list:
                thr.join()
        save_file.close()
    
    def write_header(self, header_string):
        with open(self.save_location, "w", encoding='utf-8') as f:
            f.write(header_string + '\n')
