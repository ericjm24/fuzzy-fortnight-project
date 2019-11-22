import os
from threading import Thread
import bz2
import json
from queue import Queue, Empty

class SafeWriter:
    """
    This class borrowed from stackoverflow user:
        Leonid Mednikov
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
    def __init__(self, archive_location, save_location, num_threads=4):
        from math import ceil
        self._num_threads = ceil(num_threads)
        self.archive_location = archive_location
        self.save_location = save_location
        self.file_list = []
        try:
            for (root, dirs, file) in os.walk(self.archive_location):
                if file:
                    for f in file:
                        self.file_list.append(os.path.join(root, f))
        except:
            print("Warning: File list not loaded from supplied directory.")

    def _split_files_multi(self):
        n_split = max(self._num_threads - 1,1)
        if n_split < 2:
            return [self.file_list]
        else:
            split_list = [self.file_list[j::n_split] for j in range(n_split)]
            return split_list

    def _parse_archive_minute(self, func, tweet_file, save_file, *args):
        with bz2.open(tweet_file, mode="rt") as f:
            for tweet in f:
                ob = json.loads(tweet)
                if ob:
                    save_file.write(func(ob,*args))

    def _parse_archive_minute_list(self, func, f_list, save_file, *args):
        for tweet_file in f_list:
            self._parse_archive_minute(func, tweet_file, save_file, *args)
        print("Thread finished\n")

    def parse_archive(self, func, *args):
        if self._num_threads < 2:
            save_file = open(self.save_location, "w", encoding='utf-8-sig')
            self._parse_archive_minute_list(func, self.file_list, save_file, *args)
        else:
            save_file = SafeWriter(self.save_location, "w", encoding='utf-8-sig')
            f_lists = self._split_files_multi()
            thr_list = []
            for f_list in f_lists:
                temp = Thread(target=self._parse_archive_minute_list, args = (func, f_list, save_file, *args))
                thr_list.append(temp)
                temp.start()
            for thr in thr_list:
                thr.join()
        save_file.close()
