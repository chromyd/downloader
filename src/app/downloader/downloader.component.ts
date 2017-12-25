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

  downloadLimit = 10;

  constructor(private downloadService: DownloadService) { }

  static basename(url: string): string {
    return url.replace(/.*\/([^?]*).*/, '$1');
  }

  ngOnInit() {
  }

  download() {
    console.log(`Now downloading ${this.downloadUrl}`);
    const subject = this.downloadService.getFile(this.downloadUrl);
    const reader = new FileReader();

    this.baseUrl = this.downloadUrl.substr(0, this.downloadUrl.lastIndexOf('/'));

    reader.onload = () => this.processList(reader.result);

    subject.subscribe(fileData => FileSaver.saveAs(fileData, DownloaderComponent.basename(this.downloadUrl)));
    subject.subscribe( fileData => reader.readAsText(fileData));
  }

  getKey(url: string) {
    console.log(`Now getting key ${url}`);
    this.downloadService.getKey(url)
      .subscribe(buffer => FileSaver.saveAs(new Blob([buffer]), `${DownloaderComponent.basename(url)}.key`));
  }

  processList(text: string) {
    console.log(`Contents for ${this.downloadUrl}:`);
    text.split('\n').forEach(e => this.processLine(e));
  }

  processLine(text: string) {
    if (!text.startsWith('#')) {
      if (this.downloadLimit > 0) {
        const localName = text.replace(/\//g, '_');
        console.log(`Get: ${this.baseUrl}/${text} as ${localName}`);
        --this.downloadLimit;
      }
    } else {
      const [, keyUrl, iv] = this.keyPattern.exec(text) || [, null, null];

      if (keyUrl && keyUrl !== this.lastKeyUrl) {
        console.log(`URL=${keyUrl}, IV=${iv}`);
        this.getKey(keyUrl);
        this.lastKeyUrl = keyUrl;
      }
    }
  }
}
