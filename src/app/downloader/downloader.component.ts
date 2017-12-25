import { Component, OnInit } from '@angular/core';
import * as FileSaver from 'file-saver';
import {DownloadService} from './download.service';

@Component({
  selector: 'app-downloader',
  templateUrl: './downloader.component.html',
  styleUrls: ['./downloader.component.css']
})
export class DownloaderComponent implements OnInit {

  downloadUrl = '';

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

    reader.onload = () => this.processList(reader.result);

    subject.subscribe(fileData => FileSaver.saveAs(fileData, DownloaderComponent.basename(this.downloadUrl)));
    subject.subscribe( fileData => reader.readAsText(fileData));
  }

  getKey() {
    console.log(`Now getting key ${this.downloadUrl}`);
    this.downloadService.getKey(this.downloadUrl)
      .subscribe(buffer => FileSaver.saveAs(new Blob([buffer]), `${DownloaderComponent.basename(this.downloadUrl)}.key`));
  }

  processList(text: string) {
    console.log(`Contents for ${this.downloadUrl}: ${text}`);
  }
}
