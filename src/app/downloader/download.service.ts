import { Injectable } from '@angular/core';
import { Http, Response, RequestOptions, ResponseContentType } from '@angular/http';
import { Observable } from 'rxjs/Observable';
// import 'rxjs/Rx';

@Injectable()
export class DownloadService {

  constructor(private http: Http) { }

  public getFile(path: string): Observable<Blob> {
    const options = new RequestOptions({responseType: ResponseContentType.Blob});

    return this.http.get(path, options)
      .map((response: Response) => <Blob>response.blob())
      .catch(error => console.log(`Oh-no: ${JSON.stringify(error)}`));
  }

}
