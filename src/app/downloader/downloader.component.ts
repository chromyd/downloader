import { Component, OnInit } from '@angular/core';
import * as FileSaver from 'file-saver';
import {DownloadService} from './download.service';

@Component({
  selector: 'app-downloader',
  templateUrl: './downloader.component.html',
  styleUrls: ['./downloader.component.css']
})
export class DownloaderComponent implements OnInit {

  keyPattern = /^#EXT-X-KEY.*URI="([^"]*)".*IV=0x(.*)/;
  downloadUrl = '';
  lastKeyUrl = '';
  baseUrl = '';

  detailedProgress = false;

  downloadLimit = 3;

  totalCount = 1;
  downloadedCount = 0;
  failedCount = 0;

  constructor(private downloadService: DownloadService) { }

  static basename(url: string): string {
    return url.replace(/.*\/([^?]*).*/, '$1');
  }

  ngOnInit() {
  }

  download() {
    const subject = this.downloadService.getFile(this.downloadUrl);
    const reader = new FileReader();

    this.baseUrl = this.downloadUrl.substr(0, this.downloadUrl.lastIndexOf('/'));

    reader.onload = () => this.processList(reader.result);

    subject.subscribe(fileData => FileSaver.saveAs(fileData, DownloaderComponent.basename(this.downloadUrl)));
    subject.subscribe( fileData => reader.readAsText(fileData));
  }

  getKey(url: string) {
    console.log(`Getting key ${url}`);
    this.downloadService.getKey(url)
      .subscribe(buffer => FileSaver.saveAs(new Blob([buffer]), `${DownloaderComponent.basename(url)}.key`));
  }

  downloadFile(url: string, localName: string) {
    this.downloadService.getFile(url).subscribe(
      fileData => this.onDownloadSucceeded(fileData, localName),
      error => this.onDownloadFailed(url, error)
    );
  }

  private onDownloadSucceeded(fileData: Blob, localName: string) {
    ++this.downloadedCount;
    FileSaver.saveAs(fileData, localName);
  }

  private onDownloadFailed(url: string, error: Error) {
    ++this.failedCount;
    console.log(`Failed to download ${url}: ${error}`);
  }

  getProgress(): number {
    return (this.downloadedCount + this.failedCount) / this.totalCount;
  }

  processList(text: string) {
    this.prepare(text);
    text.split('\n').forEach(e => this.processLine(e));
  }

  prepare(text: string) {
    this.totalCount = text.split('\n').filter(e => e && !e.startsWith('#')).length;
  }

  processLine(text: string) {
    if (text && !text.startsWith('#')) {
      if (this.downloadLimit > 0) {
        const localName = text.replace(/\//g, '_');
        this.downloadFile(`${this.baseUrl}/${text}`, localName);
      }
    } else {
      const [, keyUrl] = this.keyPattern.exec(text) || [, null];

      if (keyUrl && keyUrl !== this.lastKeyUrl) {
        this.getKey(keyUrl);
        this.lastKeyUrl = keyUrl;
      }
    }
  }
}
