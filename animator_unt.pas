unit animator_unt;

{$mode delphi}{$H+}



interface
uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Menus;

type
   TMainForm = class;
  //класс вершины

  { TVertex }

  TVertex = class(TShape)
    constructor Create(OwnerForm: TMainForm);
    procedure Paint; override;
  private
    lstAdjacent: TList;
    blDragingFlag: boolean;
    pntCursorOffset:TPoint;
    procedure setCursorOffset(pntOffset:TPoint);
    function getCursorOffset:TPoint;
    function isDraging: boolean;
    procedure startDraging;
    procedure stopDraging;
  end;

  { TMainForm }

  TMainForm = class(TForm)
    btnCreateFrame: TButton;
    btnDeleteFrame: TButton;
    btnDeleteVert: TButton;
    btnCreateVert: TButton;
    btnCreateEdge: TButton;
    btnDeleteEdge: TButton;
    dlgOpen: TOpenDialog;
    mitQuit: TMenuItem;
    mitSave: TMenuItem;
    mitOpen: TMenuItem;
    mnmMenu: TMainMenu;
    mitFile: TMenuItem;
    pnlFrameArea: TPanel;
    dlgSave: TSaveDialog;
    procedure btnCreateEdgeClick(Sender: TObject);
    procedure btnCreateFrameClick(Sender: TObject);
    procedure btnCreateVertClick(Sender: TObject);
    procedure btnDeleteEdgeClick(Sender: TObject);
    procedure btnDeleteFrameClick(Sender: TObject);
    procedure btnDeleteVertClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure mitSaveClick(Sender: TObject);
    procedure mitOpenClick(Sender: TObject);
    procedure mitQuitClick(Sender: TObject);
    procedure VertexOnMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pnlFrameAreaClick(Sender: TObject);

    procedure VertexOnMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure VertexOnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NextFrame();
    procedure PrevFrame();

  private
    lstFrameList: TList;     //список кадров
    iIndex: integer;         //номер текущего кадра
    vrtInFocus: TVertex;     //точка в фокусе

    blCreatingVertFlag: boolean;  //флаг состояния создания новой вершины

    blCreatingEdgeFlag: boolean;  //флаг состояния создания нового ребра
    blDeletingEdgeFlag: boolean;  //флаг состояния удаления нового ребра

    procedure ClearAll;
    procedure ClearFrame;
    procedure CopyList;
    procedure DrawFrame;
    procedure InfoOut;
    { private declarations }
  public
    function getFocusVertex:TVertex;
    procedure setFocusVertex(vrtNewFocus:TVertex);

    function isCreatingVert:boolean;
    procedure startCreatingVert;
    procedure stopCreatingVert;

    function isCreatingEdge:boolean;
    function isDeletingEdge:boolean;
    procedure startCreatingEdge;
    procedure startDeletingEdge;
    procedure stopCreatingEdge;
    procedure stopDeletingEdge;
    { public declarations }
  end;



const
     _NOCURRENTFRAME = 'No Current Frame' ;
     _VERTEXDIAM = 10;


var
  MainForm: TMainForm;
implementation

{ TVertex }

constructor TVertex.Create(OwnerForm: TMainForm);
begin
  inherited Create(OwnerForm); //задание владельца
  Shape:=stCircle;             // неизменяемые параметры
  Height:=_VERTEXDIAM;          // вершины
  Width:=_VERTEXDIAM;           //
  blDragingFlag:=FALSE;
  lstAdjacent:=TList.Create;   //список других соединенных вершин

  OnMouseDown:=OwnerForm.VertexOnMouseDown;
  OnMouseUp:=OwnerForm.VertexOnMouseUp;
  OnMouseMove:=OwnerForm.VertexOnMouseMove;

end;

procedure TVertex.Paint;
begin
    if self = (Owner as TMainForm).getFocusVertex then
    self.Brush.Color:=clRed
    else                          //прорисовка зависит от того,
    self.Brush.Color:=clWhite;    //выделена ли вершина

    inherited Paint;


end;

procedure TVertex.setCursorOffset(pntOffset: TPoint);
begin
  pntCursorOffset:=pntOffset;
end;

function TVertex.getCursorOffset: TPoint;
begin
     getCursorOffset:=pntCursorOffset;
end;

function TVertex.isDraging: boolean;
begin
  isDraging:=blDragingFlag;
end;

procedure TVertex.startDraging;
begin
     blDragingFlag:=TRUE;
end;

procedure TVertex.stopDraging;
begin
     blDragingFlag:=FALSE;
end;

{$R *.lfm}

{ TMainForm }

procedure TMainForm.VertexOnMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  pntOffset:TPoint;
begin
     if isCreatingEdge then                      //сначала обработка, если
     begin                                       //происходиn создания ребра
         if Sender=vrtInFocus then
            showmessage('Chose another vertex.') //проверка на глупость
         else if (sender as TVertex).lstAdjacent.IndexOf(vrtInFocus)<>-1 then
            showmessage('Chose another vertex')
         else
         begin
         vrtInFocus.lstAdjacent.Add(sender);
         (sender as TVertex).lstAdjacent.Add(vrtInFocus);

         stopCreatingEdge;

         ClearFrame;
         DrawFrame;
         end;
     end
     else if isDeletingEdge then                 //потом случай удаления ребра
     begin
          if Sender=vrtInFocus then
            showmessage('Chose another vertex.') //проверка на глупость
          else if (sender as TVertex).lstAdjacent.IndexOf(vrtInFocus)=-1 then
              showmessage('Chose another vertex')
          else
          begin
               //удаление ссылки с одной стороны
               vrtInFocus.lstAdjacent.Delete(
               vrtInFocus.lstAdjacent.IndexOf(sender));
               //удаление ссылки с другой стороны
               (sender as TVertex).lstAdjacent.Delete(
               (sender as TVertex).lstAdjacent.IndexOf(vrtInFocus) );

               stopDeletingEdge;

               ClearFrame;
               DrawFrame;
          end;
     end
     else
     begin                               //и наконец просто выделение вершины
          vrtInFocus:= (Sender as TVertex);
          vrtInFocus.startDraging;

          pntOffset.x:=x;
          pntOffset.y:=y;

          (Sender as TVertex).setCursorOffset(pntOffset);

          ClearFrame;
          DrawFrame;
     end;
end;

procedure TMainForm.VertexOnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
    vrtInFocus.stopDraging;
end;

procedure TMainForm.setFocusVertex(vrtNewFocus: TVertex);
begin
  vrtInFocus:= vrtNewFocus;
end;

function TMainForm.isCreatingVert: boolean;
begin
      isCreatingVert:= blCreatingVertFlag;
end;

procedure TMainForm.startCreatingVert;
begin
     btnCreateVert.Caption:='Cancel';
     blCreatingVertFlag:=TRUE;

end;

procedure TMainForm.stopCreatingVert;
begin
    btnCreateVert.Caption:='Create Vertex';
    blCreatingVertFlag:=FALSE;
end;

function TMainForm.isCreatingEdge: boolean;
begin
     isCreatingEdge:= blCreatingEdgeFlag;
end;

function TMainForm.isDeletingEdge: boolean;
begin
     isDeletingEdge:=blDeletingEdgeFlag;
end;

procedure TMainForm.startCreatingEdge;
begin
     btnCreateEdge.caption:='Cancel';
     blCreatingEdgeFlag:=TRUE;
end;

procedure TMainForm.startDeletingEdge;
begin
     btnDeleteEdge.caption:='Cancel';
     blDeletingEdgeFlag:=TRUE;
end;

procedure TMainForm.stopCreatingEdge;
begin
     btnCreateEdge.Caption:='Create Edge';
     blCreatingEdgeFlag:=FALSE;
end;

procedure TMainForm.stopDeletingEdge;
begin
     btnDeleteEdge.caption:='Delete Edge';
     blDeletingEdgeFlag:=FALSE;
end;

function TMainForm.getFocusVertex:TVertex;
begin
  getFocusVertex:=vrtInFocus;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
    case Key of
         $41:PrevFrame;
         $44:NextFrame;
    end;
end;

procedure TMainForm.mitSaveClick(Sender: TObject);
var
   flSave: file of integer;
   i,k,c:integer;
begin
     if dlgSave.Execute then
       begin
       showmessage(dlgSave.FileName);
       assignfile(flSave, dlgSave.FileName);
       rewrite(flSave);

       write(flSave, lstFrameList.Count);   //запись количества кадров

       for i:=0 to lstFrameList.Count-1 do
       begin
            write(flSave, TList(lstFrameList[i]).Count); //запись количества вершин
            for k:=0 to TList(lstFrameList[i]).Count-1 do
            begin
                 with TVertex(TList(lstFrameList[i]).Items[k]) do
                 begin
                   write(flSave, Left);                 //координаты
                   write(flSave, Top);
                   write(flSave, lstAdjacent.Count);    //количество соединений
                   for c:=0 to lstAdjacent.Count-1 do
                   begin
                      write(flSave,
                      TList(lstFrameList[i]).IndexOf(lstAdjacent[c])); //соединения с какими точками
                   end;
                 end;
            end;
       end;
       closefile(flSave);
     end;
end;

procedure TMainForm.ClearAll;
var
   i,k:integer;
begin
    for i:=0 to lstFrameList.Count-1 do
     begin
          for k:=0 to TList(lstFrameList[i]).Count-1 do
          begin
               with TVertex(TList(lstFrameList[i]).Items[k]) do
               begin
                    lstAdjacent.Free;
                    Free; //вообще говоря, не обязательно
               end;       //так как форма как владелец сама вычистит вершины
          end;
          TList(lstFrameList[i]).Free;
     end;
    lstFrameList.Free;
    vrtInFocus:=nil;
    iIndex:=-1;
    ClearFrame;
end;

procedure TMainForm.mitOpenClick(Sender: TObject);
var
   iFrameAmount, iVertAmount, iAdjAmount, x,y, iAdjIndex:integer;
   i,k,c:integer;
   iSeekMarker:integer;  //маркер для повторного чтения из файла
   flOpen: file of integer;
begin
     if dlgOpen.Execute then
     begin
          ClearAll;
          iSeekMarker:=0;

          lstFrameList:=TList.Create;

          assignfile(flOpen, dlgOpen.FileName);
          reset(flOpen);

          read(flOpen, iFrameAmount); inc(iSeekMarker);  //количество кадров
          for i:=0 to iFrameAmount-1 do
          begin
               seek(flOpen, iSeekMarker);
               lstFrameList.Add(TList.Create);
               read(flOpen, iVertAmount); inc(iSeekMarker); //количество вершин
               for k:=0 to iVertAmount-1 do
               begin
                  with TList(lstFrameList[i]) do
                  begin
                     seek(flOpen, iSeekMarker);
                     read(flOpen, x); inc(iSeekMarker);    //координаты
                     read(flOpen, y); inc(iSeekMarker);
                     Add(TVertex.Create(self));
                     with TVertex(TList(lstFrameList[i]).Items[k]) do
                     begin
                        Left:=x;
                        Top:=y;
                        read(flOpen, iAdjAmount); inc(iSeekMarker);    //количество соединений
                        for c:=0 to iAdjAmount-1 do
                        begin
                          inc(iSeekMarker);    //больше ничего пока читать
                        end;                   //не нежно, просто двигается
                     end;                      //маркер
                  end;
               end;
          end;

          iSeekMarker:=0;

          inc(iSeekMarker);
          for i:=0 to lstFrameList.Count-1 do
          begin
            inc(iSeekMarker);
            for k:=0 to TList(lstFrameList[i]).Count-1 do
            begin
              inc(iSeekMarker);
              inc(iSeekMarker);
               with TVertex(TList(lstFrameList[i]).Items[k]) do
               begin
                 seek(flOpen, iSeekMarker);
                 read(flOpen, iAdjAmount); inc(iSeekMarker);
                 for c:=0 to iAdjAmount-1 do
                 begin
                      read(flOpen, iAdjIndex); inc(iSeekMarker);
                      lstAdjacent.Add(
                       TList(lstFrameList[i]).Items[iAdjIndex]);
                 end;
               end;
            end;
          end;

     closefile(flOpen);
     iIndex:=0;
     vrtInFocus:=TList(lstFrameList.First).First;

     if vrtInFocus<>nil then btnDeleteVert.Enabled:=TRUE;

     btnCreateVert.Enabled:=TRUE;
     btnDeleteFrame.Enabled:=TRUE;
     btnCreateEdge.Enabled:=TRUE;
     btnDeleteEdge.Enabled:=TRUE;
     mitSave.Enabled:=TRUE;

     DrawFrame;
    end;
end;

procedure TMainForm.mitQuitClick(Sender: TObject);
begin
  ClearAll;
  Self.Close;
end;

procedure TMainForm.InfoOut;
var
  strInfo:string;
begin
     if iIndex = -1 then strInfo:=_NOCURRENTFRAME //здесь отображение номера кадра
     else strInfo:= inttostr(iIndex+1)+'/'+inttostr(lstFrameList.count);

     pnlFrameArea.Canvas.TextOut(
         pnlFrameArea.Width-pnlFrameArea.Canvas.TextWidth(strInfo),
         pnlFrameArea.Canvas.TextHeight(strInfo),
         strInfo);
end;

procedure TMainForm.pnlFrameAreaClick(Sender: TObject);
var
  msMouse: TMouse;
  pos: TPoint;
begin
  if isCreatingVert then                       //если была нажата кнопка создания вершины
  begin
       vrtInFocus:=TVertex.Create(self);       //создание новой вершины

       pos.x:=msMouse.CursorPos.x;             //задание нужных координат
       pos.y:=msMouse.CursorPos.y;
       pos:=pnlFrameArea.ScreenToClient(pos);

       vrtInFocus.Top:=pos.y-_VERTEXDIAM div 2;
       vrtInFocus.Left:=pos.x-_VERTEXDIAM div 2;



       TList(lstFrameList.Items[iIndex]).Add(vrtInFocus);

       ClearFrame;
       DrawFrame;

       stopCreatingVert;                           //закончить создание

       btnDeleteVert.Enabled:=TRUE;
       btnCreateEdge.Enabled:=TRUE;
  end;

end;

procedure TMainForm.CopyList;
var
  lstOrigin, lstDest:TList;
  i,k:integer;
begin
     lstOrigin:=lstFrameList[iIndex-1];
     lstDest:=lstFrameList[iIndex];
     for i:=0 to lstOrigin.Count-1 do        //копируется каждая вершина
     begin
         lstDest.Add(TVertex.Create(self));  //создается копия
         TVertex(lstDest[i]).Left:=TVertex(lstOrigin[i]).Left;
         TVertex(lstDest[i]).Top:=TVertex(lstOrigin[i]).Top;
     end;

     for i:=0 to lstOrigin.Count-1 do  //создается такой же список соединенных вершин
     begin
         with TVertex(lstOrigin[i]) do
         begin
              for k:=0 to lstAdjacent.Count-1 do
              begin
                  TVertex(lstDest[i]).lstAdjacent.Add(
                  lstDest[lstOrigin.IndexOf(lstAdjacent[k])]);
              end;

         end;
     end;
end;

procedure TMainForm.btnCreateFrameClick(Sender: TObject);
begin
     ClearFrame;
     if iIndex = -1 then
     begin
          btnDeleteFrame.Enabled:=TRUE;
          btnCreateVert.Enabled:=TRUE;

          btnCreateEdge.Enabled:=TRUE;
          btnDeleteEdge.Enabled:=TRUE;

          mitSave.Enabled:=TRUE;
     end;
     inc(iIndex);
     lstFrameList.Add(TList.Create);
     if iIndex>0 then          //новый кадр повторяет предыдущий
     begin
         CopyList;

     end;
     vrtInFocus:=TList(lstFrameList[iIndex]).First;
     DrawFrame;
end;

procedure TMainForm.btnDeleteFrameClick(Sender: TObject);
begin
     ClearFrame;
     if iIndex>-1 then
     begin
          lstFrameList.Delete(iIndex);
          if (iIndex <> 0) or (lstFrameList.Count=0) then
          dec(iIndex)
     end;
     if iIndex = -1 then
     begin
          btnDeleteFrame.Enabled:=FALSE;
          btnCreateVert.Enabled:=FALSE;
          btnDeleteVert.Enabled:=FALSE;

          btnCreateEdge.Enabled:=FALSE;
          btnDeleteEdge.Enabled:=FALSE;

          mitSave.Enabled:=FALSE;
     end;
     if iIndex<>-1 then vrtInFocus:=TList(lstFrameList[iIndex]).First
     else vrtInFocus:=nil;
     DrawFrame;
end;

procedure TMainForm.btnCreateVertClick(Sender: TObject);
begin
   case blCreatingVertFlag of
        TRUE: begin
          stopCreatingVert;
        end;
        FALSE: begin
          startCreatingVert;
        end;
   end;
end;

procedure TMainForm.btnCreateEdgeClick(Sender: TObject);
begin
     case blCreatingEdgeFlag of
        TRUE: begin
          stopCreatingEdge;
        end;
        FALSE: begin
          startCreatingEdge;
        end;
     end;
end;

procedure TMainForm.btnDeleteEdgeClick(Sender: TObject);
begin
     case blDeletingEdgeFlag of
        TRUE: begin
          stopDeletingEdge;
        end;
        FALSE: begin
          startDeletingEdge;
        end;
     end;
end;

procedure TMainForm.VertexOnMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  with (Sender as TVertex) do
  begin
     if isDraging then
     begin
      Left:=Left+X-getCursorOffset.x;
      Top:=Top+Y-getCursorOffset.y;
      ClearFrame;
      DrawFrame;
     end;
  end;
end;

procedure TMainForm.btnDeleteVertClick(Sender: TObject);
var
  i:integer;
begin
//удаление ссылок на вершину из всех
//из всех списков соединных с ней
     for i:=0 to vrtInFocus.lstAdjacent.Count-1 do
     begin
       with TVertex(vrtInFocus.lstAdjacent[i]) do
       begin
          lstAdjacent.Delete(
          lstAdjacent.IndexOf(vrtInFocus));
       end;
     end;

     vrtInFocus.Free;    //уничтожение самого объекта и удаление из
     i:=TList(lstFrameList[iIndex]).IndexOf(vrtInFocus);//общего списка ссылки
     TList(lstFrameList[iIndex]).Delete(i);

     vrtInFocus:=TList(lstFrameList[iIndex]).First;
     ClearFrame;
     DrawFrame;

     if vrtInFocus = nil then
        btnDeleteVert.Enabled:=FALSE;
end;

procedure TMainForm.DrawFrame;
var
  i,k:integer;
  current:TVertex;
begin
  InfoOut;
  if iIndex<>-1 then
    begin
         for i:=0 to TList(lstFrameList.Items[iIndex]).Count-1 do
         begin
           current:= TVertex(TList(lstFrameList.Items[iIndex]).Items[i]);
           with current do
           begin
                Parent:=pnlFrameArea;
                pnlFrameArea.Canvas.Brush.Color:=clBlack;
                for k:=0 to lstAdjacent.Count-1 do

                pnlFrameArea.Canvas.Line(
                      left+(_VERTEXDIAM div 2), top+(_VERTEXDIAM div 2),
                      TVertex(lstAdjacent[k]).Left+(_VERTEXDIAM div 2),
                      TVertex(lstAdjacent[k]).Top+(_VERTEXDIAM div 2));
           end;
         end;

    end;
end;

procedure TMainForm.ClearFrame;
var
  i:integer;
  current: TVertex;
begin
     if iIndex<>-1 then
     begin
         for i:=0 to TList(lstFrameList.Items[iIndex]).Count-1 do
         begin
           current:= TVertex(TList(lstFrameList.Items[iIndex]).Items[i]);
           with current do
           begin
               pnlFrameArea.Canvas.Brush.Color:=clWhite;
               Parent:=nil;
           end;
         end;
    end;
     pnlFrameArea.Canvas.Brush.Color:=clWhite;
     pnlFrameArea.Canvas.FillRect(0,0,pnlFrameArea.Width,pnlFrameArea.Height);
end;

procedure TMainForm.NextFrame;
begin
     ClearFrame;
     if iIndex+1<lstFrameList.Count then inc(iIndex);

     vrtInFocus:=TList(lstFrameList[iIndex]).First;
     DrawFrame;
end;

procedure TMainForm.PrevFrame;
begin
     ClearFrame;
     if iIndex>0 then dec(iIndex);
     if iIndex<>-1 then vrtInFocus:=TList(lstFrameList[iIndex]).First
     else vrtInFocus:=nil;
     DrawFrame;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
    iIndex:= -1;
    lstFrameList:=TList.Create;
    vrtInFocus:=nil;
    InfoOut;
end;

end.

