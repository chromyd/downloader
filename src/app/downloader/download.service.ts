import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import 'rxjs/add/operator/map';
import { Observable } from 'rxjs/Observable';

@Injectable()
export class DownloadService {

  constructor(private http: HttpClient) { }

  public getFile(path: string): Observable<Blob> {
    return this.http.get(path, {responseType: 'blob'});
  }

  public getKey(path: string): Observable<string> {
    return this.http.get(path, {responseType: 'arraybuffer', withCredentials: true})
      .map(buffer => Array.from(new Uint8Array(buffer)))
      .map(array => array.map(e => ('0' + e.toString(16)).substr(-2)).join(''));
  }

}
