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
  downloadingSegments = false;

  segments: string[];
  index = 0;
  downloaded = 0;

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
      .replace('450K/450_', '5600K/5600_')
      .replace('800K/800_', '5600K/5600_')
      .replace('1200K/1200_', '5600K/5600_')
      .replace('1800K/1800_', '5600K/5600_')
      .replace('2500K/2500_', '5600K/5600_')
      .replace('3500K/3500_', '5600K/5600_');
  }

  download() {
    console.log(`Downloading ${this.downloadUrl}`);
    this.reset();
    const subject = this.downloadService.getFile(this.downloadUrl);
    const reader = new FileReader();

    this.baseUrl = this.downloadUrl.substr(0, this.downloadUrl.lastIndexOf('/'));

    reader.onload = () => this.processList(reader.result);

    subject.subscribe(fileData => FileSaver.saveAs(fileData, DownloaderComponent.friendlyName(this.downloadUrl)));
    subject.subscribe( fileData => reader.readAsText(fileData));
  }

  retryFailedSegments() {
    const from = this.baseUrl.length + 1;
    const segmentList = this.failedUrls.map(s => s.substr(from)).join('\n');
    this.reset();
    this.prepare(segmentList);
    this.startDownloadingSegments();
  }

  private reset() {
    this.totalCount = 1;
    this.index = this.downloaded = 0;
    this.failedUrls = [];
    this.message = DOWNLOADING_KEYS;
    this.downloading = true;
  }

  private getKey(url: string) {
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
      this.startDownloadingSegments();
    }
  }

  private startDownloadingSegments() {
    this.message = '';
    this.downloadingSegments = true;

    this.doNext();
    this.doNext();
    this.doNext();
    this.doNext();
  }

  private downloadFile(url: string, localName: string) {
    this.downloadService.getFile(url).subscribe(
      fileData => this.onDownloadSucceeded(fileData, localName),
      error => this.onDownloadFailed(url, error)
    );
  }

  private onDownloadSucceeded(fileData: Blob, localName: string) {
    ++this.downloaded;
    FileSaver.saveAs(fileData, localName);
    this.afterDownload();
  }

  private onDownloadFailed(url: string, error: Error) {
    this.failedUrls.unshift(url);
    console.log(`Failed to download ${url}: ${error}`);
    this.afterDownload();
  }

  private afterDownload() {
    if (this.downloaded + this.failedUrls.length === this.totalCount) {
      this.finalReport();
    } else {
      this.doNext();
    }
  }

  private doNext() {
    if (this.index < this.totalCount) {
      this.getNextSegment();
      ++this.index;
    }
  }

  private finalReport() {
    this.downloading = this.downloadingSegments = false;
    if (this.failedUrls.length > 0) {
      this.message = 'Not all segments were downloaded.';
    } else if (this.missingKeys > 0) {
      this.message = 'Not all keys were downloaded.';
    } else {
      console.log('Done');
      this.message = FINISHED;
    }
  }

  getProgress(): number {
    return this.downloaded / this.totalCount;
  }

  private isHealthy(): boolean {
    return this.failedUrls.length === 0;
  }

  getProgressBarColor(): string {
    return this.isHealthy() ? 'dodgerblue' : 'deeppink';
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
    this.segments = text.split('\n').filter(e => e && !e.startsWith('#'));
    this.totalCount = this.segments.length;
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

  private getNextSegment() {
    const localName = this.segments[this.index].replace(/\//g, '_');
    this.downloadFile(`${this.baseUrl}/${this.segments[this.index]}`, localName);
  }
}
