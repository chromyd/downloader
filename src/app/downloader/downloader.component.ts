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

  ngOnInit() {
  }

  download() {
    console.log(`Now downloading ${this.downloadUrl}`);
    this.downloadService.getFile(this.downloadUrl)
      .subscribe(fileData => FileSaver.saveAs(fileData, 'saved.data'));
  }

}
