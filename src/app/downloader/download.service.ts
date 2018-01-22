import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs/Observable';
import 'rxjs/add/operator/map';
import 'rxjs/add/operator/retry';
import 'rxjs/add/operator/timeout';

@Injectable()
export class DownloadService {

  constructor(private http: HttpClient) { }

  public getFile(path: string): Observable<Blob> {
    return this.http.get(path, {responseType: 'blob'}).timeout(15000).retry(4);
  }

  public getKey(path: string): Observable<string> {
    return this.http.get(path, {responseType: 'arraybuffer', withCredentials: true}).retry(3)
      .map(buffer => Array.from(new Uint8Array(buffer)))
      .map(array => array.map(e => ('0' + e.toString(16)).substr(-2)).join(''));
  }

}
