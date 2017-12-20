import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs/Observable';

@Injectable()
export class DownloadService {

  constructor(private http: HttpClient) { }

  public getFile(path: string): Observable<Blob> {

    return this.http.get(path, {responseType: 'blob'});
      // .map((response: Response) => <Blob>response.blob())
      /*
      .pipe(
        catchError((error: any) => console.log(`Oh-no: ${JSON.stringify(error)}`))
      );
      */
      // .catch((fuck: any) => console.log('Fuckingham'));
      // .catch((error: Error) => console.log(`Oh-no: ${JSON.stringify(error)}`));
  }

}
