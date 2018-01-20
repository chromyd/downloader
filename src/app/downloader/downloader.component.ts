import { Component, OnInit } from '@angular/core';
import * as FileSaver from 'file-saver';
import {DownloadService} from './download.service';

const FINISHED = 'Finished';
const DOWNLOADING_KEYS = 'Downloading keys ...';

@Component({
  selector: 'app-downloader',
  templateUrl: './downloader.component.html',
  styleUrls: ['./downloader.component.css']
})
export class DownloaderComponent implements OnInit {

  keyPattern = /^#EXT-X-KEY.*URI="([^"]*)".*IV=0x(.*)/;
  downloadUrl = '';
  baseUrl = '';

  detailedProgress = false;

  totalCount = 1;
  failedUrls: string[] = [];
  missingKeys: number;

  message = '';
  downloading = false;
  downloadingData = false;

  chunks: string[];
  index = 0;

  constructor(private downloadService: DownloadService) { }

  static basename(url: string): string {
    return url.replace(/.*\/([^?]*).*/, '$1');
  }

  static friendlyName(playlistUrl: string) {
    return playlistUrl.replace(/.*NHL_GAME_VIDEO_([A-Z]{3})([A-Z]{3}).*_(20[0-9]{6})_.*/, '$3-$1@$2');
  }

  ngOnInit() {
  }

  transformUrl() {
    this.downloadUrl = this.downloadUrl
      .replace('450K/450_', '3500K/3500_')
      .replace('800K/800_', '3500K/3500_')
      .replace('1200K/1200_', '3500K/3500_')
      .replace('1800K/1800_', '3500K/3500_')
      .replace('2500K/2500_', '3500K/3500_');
  }

  download() {
    this.reset();
    const subject = this.downloadService.getFile(this.downloadUrl);
    const reader = new FileReader();

    this.baseUrl = this.downloadUrl.substr(0, this.downloadUrl.lastIndexOf('/'));

    reader.onload = () => this.processList(reader.result);

    subject.subscribe(fileData => FileSaver.saveAs(fileData, DownloaderComponent.friendlyName(this.downloadUrl)));
    subject.subscribe( fileData => reader.readAsText(fileData));
  }

  private reset() {
    this.totalCount = 1;
    this.index = 0;
    this.failedUrls = [];
    this.message = DOWNLOADING_KEYS;
    this.downloading = true;
  }

  private getKey(url: string) {
    console.log(`Getting key ${url}`);
    this.downloadService.getKey(url)
      .subscribe(
        buffer => this.onKeySucceeded(new Blob([buffer]), `${DownloaderComponent.basename(url)}.key`),
        () => this.finalReport()
      );
  }

  private onKeySucceeded(keyData: Blob, localName: string) {
    --this.missingKeys;
    FileSaver.saveAs(keyData, localName);
    if (this.missingKeys === 0) {
      this.message = '';
      this.downloadingData = true;
      this.getNextChunk();
    }
  }

  private downloadFile(url: string, localName: string) {
    this.downloadService.getFile(url).subscribe(
      fileData => this.onDownloadSucceeded(fileData, localName),
      error => this.onDownloadFailed(url, error)
    );
  }

  private onDownloadSucceeded(fileData: Blob, localName: string) {
    FileSaver.saveAs(fileData, localName);
    this.doNext();
  }

  private onDownloadFailed(url: string, error: Error) {
    this.failedUrls.unshift(url);
    console.log(`Failed to download ${url}: ${error}`);
    this.doNext();
  }

  private doNext() {
    ++this.index;
    if (this.index < this.totalCount) {
      this.getNextChunk();
    } else {
      this.finalReport();
    }
  }

  private finalReport() {
    this.downloading = this.downloadingData = false;
    if (this.failedUrls.length > 0) {
      console.log('Failed downloads:');
      this.failedUrls.forEach(url => console.log(url));
      this.message = 'Not all segments were downloaded.';
    } else if (this.missingKeys > 0) {
      this.message = 'Not all keys were downloaded.';
    } else {
      console.log('Done');
      this.message = FINISHED;
    }
  }

  getProgress(): number {
    return this.index / this.totalCount;
  }

  private isHealthy(): boolean {
    return this.failedUrls.length === 0;
  }

  getProgressColor(): string {
    return this.isHealthy() ? 'silver' : 'mistyrose';
  }

  getResultColor(): string {
    return (this.message === FINISHED) ? 'seagreen' : (this.message === DOWNLOADING_KEYS) ? 'slategrey' : 'crimson';
  }

  private processList(text: string) {
    this.prepare(text);
    this.getKeys(text);
  }

  private prepare(text: string) {
    this.chunks = text.split('\n').filter(e => e && !e.startsWith('#'));
    this.totalCount = this.chunks.length;
  }

  private getKeys(text: string) {
    const keys = new Set(
      text.split('\n')
        .filter(line => line.startsWith('#EXT-X-KEY'))
        .map(line => this.keyPattern.exec(line)[1])
    );
    this.missingKeys = keys.size;
    keys.forEach(keyUrl => this.getKey(keyUrl));
  }

  private getNextChunk() {
    const localName = this.chunks[this.index].replace(/\//g, '_');
    this.downloadFile(`${this.baseUrl}/${this.chunks[this.index]}`, localName);
  }
}
