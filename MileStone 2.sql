create database mil

go

use mil


CREATE TABLE PostGradUser (
ID INT PRIMARY KEY identity,
email varchar (50),
password varchar(20)

);
CREATE TABLE Admin(
ID INT PRIMARY KEY ,
FOREIGN KEY(ID) REFERENCES PostGradUser ON DELETE CASCADE ON UPDATE CASCADE

);


CREATE TABLE GucianStudent (
ID INT PRIMARY KEY ,
firstName varchar (20),
lastName varchar(20) ,
type varchar(10) ,
faculty varchar(20) ,
address varchar(50) ,
undergradID int,
GPA decimal(3,2), 
FOREIGN KEY(ID) REFERENCES PostGradUser ON DELETE CASCADE ON UPDATE CASCADE

);

create table NonGucianStudent(
ID INT PRIMARY KEY ,
firstName varchar (20),
lastName varchar(20) ,
type varchar(10) ,
faculty varchar(20) ,
address varchar(50) ,
GPA decimal(3,2), 
FOREIGN KEY(ID) REFERENCES PostGradUser ON DELETE CASCADE ON UPDATE CASCADE
);

create table GUCStudentPhoneNumber(
ID int,
phone varchar(20),
Primary key(ID,phone),
Foreign Key (ID) references GucianStudent  ON DELETE CASCADE ON UPDATE CASCADE
);


create table NonGUCStudentPhoneNumber(
ID int,
phone varchar(20),
Primary key(ID,phone),
Foreign Key (ID) references NonGucianStudent ON DELETE CASCADE ON UPDATE CASCADE
);


create table Course(
CourseID INT PRIMARY KEY identity,
fees decimal,
creditHrs int,
code varchar(10)

);
create table Supervisor(
ID int  ,
name varchar(50),
faculty varchar(30),
primary key(ID),
FOREIGN KEY(ID) REFERENCES PostGradUser ON DELETE CASCADE ON UPDATE CASCADE

);

create table Payment(
payment_id int  PRIMARY KEY identity,
amount decimal,
no_Installments int,
fundPercentage decimal 

)

create table Thesis(
serialNumber int  PRIMARY KEY identity ,
field varchar(20),
type varchar(10),
title varchar(30),
startDate date,
endDate date,
defenseDate date,
years  as (year(endDate)-year(startDate)),
Grade decimal ,
payment_id int ,
noExtension int,
FOREIGN KEY(payment_id) REFERENCES Payment ON DELETE CASCADE ON UPDATE CASCADE
);

 
create table Publication(
Publication_id int  PRIMARY KEY identity ,
title varchar(50),
date date,
place varchar(50),
accepted bit,
 host varchar(50)
);

create table Examiner(
ID INT PRIMARY KEY ,
ExaminerName varchar(20),
fieldOfWork varchar(20),
isNational bit
FOREIGN KEY(ID) REFERENCES PostGradUser ON DELETE CASCADE ON UPDATE CASCADE
)
create table Defense(
serialNumber int,
DefenseDate Date,
DefenseLocation varchar(15),
grade decimal,

Primary key(serialNumber, DefenseDate),
Foreign Key (serialNumber) references Thesis ON DELETE CASCADE ON UPDATE CASCADE

)
create table GUCianProgressReport(
sid int,
no int identity,
date date,
evaluation int,
state int,

serialNumber int,
supid int,
Primary key(sid,no),
Foreign Key (serialNumber) references Thesis ,
Foreign Key (supid) references Supervisor ,
Foreign Key (sid) references GucianStudent 
)
create table NonGUCianProgressReport(
sid int,
no int identity,
date date,
evaluation int,
state int,

serialNumber int,
supid int,
Primary key(sid,no),
Foreign Key (serialNumber) references Thesis ,
Foreign Key (supid) references Supervisor ,
Foreign Key (sid) references NonGucianStudent 
)
create table Installment(
Installmentdate date,
amount decimal,
paymentid int,
done bit,
primary key(Installmentdate,paymentid),
Foreign Key (paymentid) references Payment ON DELETE CASCADE ON UPDATE CASCADE
)
create table NonGucianStudentPayForCourse(
sid int,
paymentNo int,
cid int,
primary key (sid,paymentNo,cid),
Foreign Key (sid) references NonGucianStudent ON DELETE CASCADE ON UPDATE CASCADE,
Foreign Key (paymentNo) references Payment ON DELETE CASCADE ON UPDATE CASCADE,
Foreign Key (cid) references Course ON DELETE CASCADE ON UPDATE CASCADE
)
create table NonGucianStudentTakeCourse(
sid int,
cid int,
grade decimal,
primary key (sid,cid),
Foreign Key (sid) references NonGucianStudent ,
Foreign Key (cid) references Course ON DELETE CASCADE ON UPDATE CASCADE
)
create table GUCianStudentRegisterThesis(
sid int,
supid int ,
serial_no int,
primary key (sid,supid,serial_no),
Foreign Key (supid) references Supervisor ON DELETE CASCADE ON UPDATE CASCADE,
Foreign Key (serial_no) references Thesis ON DELETE CASCADE ON UPDATE CASCADE,
Foreign Key (sid) references GucianStudent
)
create table NonGUCianStudentRegisterThesis(
sid int,
supid int ,
serial_no int,
primary key (sid,supid,serial_no),
Foreign Key (supid) references Supervisor ON DELETE CASCADE ON UPDATE CASCADE,
Foreign Key (serial_no) references Thesis ON DELETE CASCADE ON UPDATE CASCADE,
Foreign Key (sid) references NonGucianStudent 
)
create table ExaminerEvaluateDefense(
date date,
serialNo int,
examinerId int,
comment varchar(300),
primary key (date,serialNo,examinerId),
Foreign Key (serialNo,date) references Defense ON DELETE CASCADE ON UPDATE CASCADE,

Foreign Key (examinerId) references Examiner ON DELETE CASCADE ON UPDATE CASCADE
);
create table ThesisHasPublication(
serialNo int,
pubid int ,
primary key (serialNo,pubid),
Foreign Key (serialNo) references Thesis ON DELETE CASCADE ON UPDATE CASCADE,
Foreign Key (pubid) references Publication ON DELETE CASCADE ON UPDATE CASCADE
);

go

create proc getidfromemailpass
@email varchar(50),
@password varchar(20),
@id int output
as
select @id=ID
from PostGradUser
where email=@email and password=@password

----------------------------------------------------------
go
/*   GucianOrNonGucian checks wether a student is a gucian or not by returning 1 if he is a gucian 
*/
create proc GucianOrNonGucian
@id int,
@out bit output 
as
if(exists (select * from GucianStudent where ID=@id ))
set @out='1'
else
set @out='0'

-----------------------------------
go
create proc getsidfromrthesis
@thesisno int,
@sid int output
as

declare @nonsid int 
Declare @gsid int

select  @nonsid=sid
from NonGUCianStudentRegisterThesis
where serial_no =@thesisno


select   @gsid=sid
from GUCianStudentRegisterThesis
where serial_no =@thesisno

if(@gsid is not null)
set @sid =@gsid
else
set @sid=@nonsid
---------------------------------------1A--Student register


go

create proc StudentRegister
@first_name varchar(20),
@last_name varchar(20),
@password varchar(20),
@faculty varchar(20),
@Gucian bit,
@email varchar(50),
@address varchar(50)
as
insert into PostGradUser values (@email,@password)
declare @id int
exec getidfromemailpass @email,@password,@id output
if @Gucian =1
insert into GucianStudent (ID,firstName,lastName,faculty,address) values (@id,@first_name,@last_name,@faculty,@address)
else
insert into NonGucianStudent (ID,firstName,lastName,faculty,address)  values (@id,@first_name,@last_name,@faculty,@address)



--------------------------------------- 1A--SUPERVISOR Register

go

create proc SupervisorRegister
@first_name varchar(20),
@last_name varchar(20),
@password varchar(20),
@faculty varchar(20),
@email varchar(50)
as
insert into PostGradUser values (@email,@password)
declare @id int
exec getidfromemailpass @email,@password,@id output
declare @name varchar(50)
set @name  =  CONCAT(@first_name,' ',@last_name)
insert into Supervisor values (@id,@name,@faculty)


---------------------------------2A---login
go

create proc userLogin
@ID int,
@password varchar(30),
@bit bit output
as
if(exists ( select *  from PostGradUser  where ID=@ID and password=@password))
set @bit='1'
else
set @bit='0' 


-------------------------------------2B--addmobile
go

create proc addMobile
@ID int,
@mobile_number varchar(20)

as
declare @isgucian bit
exec GucianOrNonGucian @ID,@isgucian output
if(@isgucian='1')
insert into GUCStudentPhoneNumber values (@ID,@mobile_number)
else
insert into NonGUCStudentPhoneNumber values (@ID,@mobile_number)


------------------------------------3A--listsupervisors

go

create proc  AdminListSup
as
select *
from Supervisor

-----------------------------------------3B---superinfo

go

create proc AdminViewSupervisorProfile
@supId int
as
select *
from Supervisor
where id=@supId


----------------------------------------3C--thesisinfo

go
create proc AdminViewAllTheses
as

select *
from Thesis

------------------------------------------3D--onGoingThesis

go

create proc AdminViewOnGoingTheses
@thesesCount int output
as

declare @Todaysdate date
set @Todaysdate= cast (CURRENT_TIMESTAMP as date)

select @thesesCount=count(*)
from Thesis
where endDate > @Todaysdate

--------------------------------------------3E--supervisingthesis
go

create proc AdminViewStudentThesisBySupervisor
as
select s.name,th.title,gs.firstName,gs.lastName
from Thesis th inner join GUCianStudentRegisterThesis sth on th.serialNumber= sth.serial_no inner join GucianStudent gs on gs.id =sth.sid 
inner join Supervisor s on s.id=sth.supid
union 
select s.name,th.title,gs.firstName,gs.lastName
from Thesis th inner join NonGUCianStudentRegisterThesis sth on th.serialNumber= sth.serial_no inner join NonGucianStudent gs on gs.id =sth.sid 
inner join Supervisor s on s.id=sth.supid


----------------------------------------------------3F--NONguciancourse
go

create proc AdminListNonGucianCourse
@courseID int
as
select s.firstName,s.lastName,c.code,nc.grade
from NonGucianStudentTakeCourse nc inner join NonGucianStudent s on nc.sid=s.ID inner join Course c on  c.CourseID=nc.cid
where c.CourseID=@courseID


------------------------------------------------------3G--thesisExtension
go

create proc AdminUpdateExtension
@ThesisSerialNo int
as
declare @noextensions int
select @noextensions=noExtension
from Thesis
where serialNumber=@ThesisSerialNo


update Thesis
set noExtension=@noextensions+1
where serialNumber=@ThesisSerialNo


------------------------------------------------------3H---thesisPayment
go

create proc AdminIssueThesisPayment

@ThesisSerialNo int, 
@amount decimal, 
@noOfInstallments int, 
@fundPercentage decimal
as
declare @paymentID int


insert into Payment values (@amount ,@noOfInstallments,@fundPercentage)
select  @paymentID=payment_id
from Payment
where amount=@amount and no_Installments=@noOfInstallments and fundPercentage=@fundPercentage

update Thesis
set payment_id=@paymentID
where serialNumber=@ThesisSerialNo


--------------------------------------------3I---viewstudent

go 

create proc AdminViewStudentProfile
@sid int
as
declare @isgucian bit 
exec GucianOrNonGucian @sid,@isgucian output
if(@isgucian='1')

select *
from GucianStudent g
where ID =@sid

else

select *
from NonGucianStudent
where ID =@sid

------------------------------------------3J----issueinstallment

go

create proc AdminIssueInstallPayment
@paymentID int,
@InstallStartDate date
as
declare @amount decimal
declare @nofinstallments int
declare @amounteachinstallment decimal
select @amount=amount,@nofinstallments=no_Installments
from Payment
where payment_id=@paymentID
set @amounteachinstallment=@amount/@nofinstallments
declare @counter int
set @counter=@nofinstallments

while (@counter>0)

begin

insert into Installment values (@InstallStartDate,@amounteachinstallment,@paymentID,'0');
set @counter = @counter-1;

set @InstallStartDate =dateadd(MONTH,6,@InstallStartDate);
end





--------------------------------------------3K---acceptPulication

go
create proc AdminListAcceptPublication
as
select t.title,p.title
from ThesisHasPublication thp inner join Thesis t on t.serialNumber=thp.serialNo inner join Publication p on p.Publication_id=thp.pubid
where p.accepted='1'



------------------------------------------3L--AddLinkCourse----------

go

create proc AddCourse
@courseCode varchar(10),
@creditHrs int,
@fees decimal
as
insert into Course values (@fees,@creditHrs,@courseCode)

go

create proc linkCourseStudent
@courseID int,
@studentID int
as
insert into NonGucianStudentTakeCourse (sid, cid) values(@studentID,@courseID)

go

create proc addStudentCourseGrade
@courseID int,
@studentID int,
@grade decimal
as
update NonGucianStudentTakeCourse
set grade = @grade
where sid=@studentID and cid=@courseID

-------------------------------3M------examsupdef-----------------------

go

create proc ViewExamSupDefense 
@defenseDate datetime
as

select e.ExaminerName
from ExaminerEvaluateDefense eed inner join  Examiner e on e.ID=eed.examinerId
where eed.date=@defenseDate

union 

select s.name
from Defense d inner join GUCianStudentRegisterThesis gsrt on d.serialNumber=gsrt.serial_no inner join  Supervisor s on s.ID=gsrt.supid
where d.DefenseDate=@defenseDate

union

select s.name
from Defense d inner join NonGUCianStudentRegisterThesis ngsrt on d.serialNumber=ngsrt.serial_no inner join  Supervisor s on s.ID=ngsrt.supid
where d.DefenseDate=@defenseDate


----------------------------------------4A---EvalProReport----------
go

create  proc EvaluateProgressReport
@supervisorID int,
@thesisSerialNo int,
@progressReportNo int,
@evaluation int
as
update NonGUCianProgressReport 
set evaluation=@evaluation
where supid=@supervisorID and serialNumber=@thesisSerialNo and no=@progressReportNo

update GUCianProgressReport 
set evaluation=@evaluation
where supid=@supervisorID and serialNumber=@thesisSerialNo and no=@progressReportNo


-------------------4B--------------------

go

create proc ViewSupStudentsYear
@supervisorID int
as
select gs.firstName,gs.lastName,th.years
from GUCianStudentRegisterThesis gsth inner join GucianStudent gs on gsth.sid=gs.ID inner join Thesis th on th.serialNumber=gsth.serial_no
where gsth.supid=@supervisorID

union

select ngs.firstName,ngs.lastName,th.years
from NonGUCianStudentRegisterThesis ngsth inner join NonGucianStudent ngs on ngsth.sid=ngs.ID inner join Thesis th on th.serialNumber=ngsth.serial_no
where ngsth.supid=@supervisorID


------------------4C--------------------

go
create proc SupViewProfile
@supervisorID int
as
select * from Supervisor

go
create proc UpdateSupProfile
@supervisorID int,
@name varchar(20),
@faculty varchar(20)
as
UPDATE Supervisor
SET Supervisor.name = @name, Supervisor.faculty = @faculty
WHERE Supervisor.ID = @supervisorID;

-------------------4D--------------------

go
create proc ViewAStudentPublications
@StudentID int
as
select P.* from GucianStudent inner join GUCianProgressReport on GucianStudent.ID = GUCianProgressReport.sid
                            inner join ThesisHasPublication on GUCianProgressReport.serialNumber = ThesisHasPublication.serialNo
                            inner join Publication P on P.Publication_id = ThesisHasPublication.pubid
                            where GucianStudent.ID = @StudentID

                            
-------------------4E--------------------
go
create proc AddDefenseGucian
@ThesisSerialNo int,
@DefenseDate Datetime,
@DefenseLocation varchar(15)
as
DECLARE @grade decimal
SET @grade = (SELECT grade FROM Thesis WHERE serialNumber = @ThesisSerialNo)
insert into Defense values(@ThesisSerialNo, @DefenseDate, @DefenseLocation, @grade)


go
create proc AddDefenseNonGucian
@ThesisSerialNo int,
@DefenseDate Datetime,
@DefenseLocation varchar(15)
as
DECLARE @grade decimal
SET @grade = (SELECT grade FROM Thesis WHERE serialNumber = @ThesisSerialNo)
if @grade > 50
insert into Defense values(@ThesisSerialNo, @DefenseDate, @DefenseLocation, @grade)



-------------------4F--------------------
go
create proc AddExaminer
@ThesisSerialNo int ,
@DefenseDate Datetime ,
@ExaminerName varchar(20),
@National bit,
@fieldOfWork varchar(20)
as
declare @id int
select  @id= ID
from Examiner
where ExaminerName=@ExaminerName and fieldOfWork=@fieldOfWork and isNational=@National



insert into ExaminerEvaluateDefense values(@DefenseDate,@ThesisSerialNo,@id,null)

-------------------4G-------------------- Check it again
go

create proc GorNoneGThesis
@ThesisSerialNo int,
@out bit output 
as
if(exists (select * from GUCianProgressReport where serialNumber = @ThesisSerialNo ))
set @out='1'
else
set @out='0'

go
create proc CancelThesis
@ThesisSerialNo int
as
DECLARE @ev int
declare @isgucian bit

exec GorNoneGThesis @ThesisSerialNo, @isgucian output
if (@isgucian='1')
SET @ev = (SELECT evaluation FROM GUCianProgressReport WHERE serialNumber = @ThesisSerialNo)
else
SET @ev = (SELECT evaluation FROM NonGUCianProgressReport WHERE serialNumber = @ThesisSerialNo)

if (@ev = '0')
delete from thesis where serialNumber = @ThesisSerialNo


-------------------4H--------------------
go
create proc AddGrade
@ThesisSerialNo int
as
DECLARE @grade decimal
SET @grade = (SELECT grade FROM Defense WHERE serialNumber = @ThesisSerialNo)
Update Thesis
set Grade = @grade where serialNumber = @ThesisSerialNo


----------------------------------------5A-------------

go
create proc AddDefenseGrade 
@ThesisSerialNo int ,
@DefenseDate Datetime ,
@grade decimal
as
update Defense 
set grade = @grade
where serialNumber = @ThesisSerialNo and @DefenseDate = @DefenseDate


----------------------------------------5B-------------

go
create proc AddCommentsGrade
@ThesisSerialNo int ,
@DefenseDate Datetime ,
@comments varchar(300)
as

update ExaminerEvaluateDefense 
set comment = @comments
where serialNo = @ThesisSerialNo and date = @DefenseDate

----------------------------------------6A-------------
go

create proc viewMyProfile 
@studentId int
as
declare @accept bit 
exec GucianOrNonGucian @studentID, @accept output

if(@accept='1')
    select * 
    from GucianStudent
    where ID = @studentId
else
    select * 
    from NonGucianStudent
    where ID = @studentId

----------------------------------------6B-------------

go

create proc editMyProfile 
@studentId int,
@firstName varchar(10), 
@lastName varchar(10), 
@password varchar(10), 
@email varchar(10), 
@address varchar(10), 
@type varchar(10)
as
declare @accept bit 
exec GucianOrNonGucian @studentID, @accept output

if(@accept='1')

    update GucianStudent 
    set firstName = @firstName, lastName = @lastName, address = @address, type = @type
    where ID = @studentId
    else
    update NonGucianStudent 
    set firstName = @firstName, lastName = @lastName, address = @address, type = @type
    where ID = @studentId

update PostGradUser
set email = @email, password = @password
where ID = @studentId


----------------------------------------6C-------------

go

create proc addUndergradID 
@studentId int,
@undergradID varchar(10)
as
update GucianStudent 
set undergradID = @undergradID
where ID = @studentID


----------------------------------------6D-------------

go

create proc ViewCoursesGrades 
@studentId int
as
select Course.CourseID as 'Course ID', NonGucianStudentTakeCourse.grade as 'Grade'
from NonGucianStudent inner join  NonGucianStudentTakeCourse on NonGucianStudent.ID = NonGucianStudentTakeCourse.sid
                      inner join  Course on NonGucianStudentTakeCourse.cid = Course.CourseID
where sid=@studentId

----------------------------------------6E-------------

go

create proc ViewCoursePaymentsInstall 
@studentId int
as 
select Course.code, Installment.amount
from NonGucianStudentPayForCourse inner join NonGucianStudent on NonGucianStudent.ID = NonGucianStudentPayForCourse.sid
                                  inner join Course on Course.CourseID = NonGucianStudentPayForCourse.cid
                                  inner join Payment on Payment.payment_id = NonGucianStudentPayForCourse.paymentNo
                                  inner join Installment on Payment.payment_id = Installment.paymentid
where NonGucianStudentPayForCourse.sid = @studentId



go

create proc ViewThesisPaymentsInstall 
@studentId int
as 
select Course.code, Installment.amount
from NonGucianStudentPayForCourse inner join NonGucianStudent on NonGucianStudent.ID = NonGucianStudentPayForCourse.sid
                                  inner join Course on Course.CourseID = NonGucianStudentPayForCourse.cid
                                  inner join Payment on Payment.payment_id = NonGucianStudentPayForCourse.paymentNo
                                  inner join Installment on Payment.payment_id = Installment.paymentid
where NonGucianStudentPayForCourse.sid = @studentId


go

create proc ViewUpcomingInstallments 
@studentId int
as 
select Installment.amount
from NonGucianStudentPayForCourse inner join NonGucianStudent on NonGucianStudent.ID = NonGucianStudentPayForCourse.sid
                                  inner join Course on Course.CourseID = NonGucianStudentPayForCourse.cid
                                  inner join Payment on Payment.payment_id = NonGucianStudentPayForCourse.paymentNo
                                  inner join Installment on Payment.payment_id = Installment.paymentid
where NonGucianStudentPayForCourse.sid = @studentId and Installmentdate > CURRENT_TIMESTAMP





go

create proc ViewMissedInstallments 
@studentId int
as 
select Installment.amount
from NonGucianStudentPayForCourse inner join NonGucianStudent on NonGucianStudent.ID = NonGucianStudentPayForCourse.sid
                                  inner join Course on Course.CourseID = NonGucianStudentPayForCourse.cid
                                  inner join Payment on Payment.payment_id = NonGucianStudentPayForCourse.paymentNo
                                  inner join Installment on Payment.payment_id = Installment.paymentid
where NonGucianStudentPayForCourse.sid = @studentId and Installmentdate < CURRENT_TIMESTAMP


----------------------------------------6F-------------

go  

create proc AddProgressReport 
@thesisSerialNo int, 
@progressReportDate date

AS

declare @id int
declare @isgucian bit
exec getsidfromrthesis @thesisSerialNo,@id output
exec GucianOrNonGucian @id,@isgucian output
declare @supid int

if(@isgucian='1')
(
select @supid=supid
from GUCianStudentRegisterThesis
where serial_no=@thesisSerialNo and sid=@id

)
else
(
select @supid=supid
from NonGUCianStudentRegisterThesis
where serial_no=@thesisSerialNo and sid=@id
)
if(@isgucian='1')
insert into GUCianProgressReport values (@id,@progressReportDate,null,null,@thesisSerialNo,@supid)
else
insert into NonGUCianProgressReport values (@id,@progressReportDate,null,null,@thesisSerialNo,@supid)

go
create proc FillProgressReport 
 @thesisSerialNo int, 
 @progressReportNo int, 
 @state int, 
 @description varchar(200)
 as
declare @id int
declare @isgucian bit

exec getsidfromrthesis @thesisSerialNo,@id output
exec GucianOrNonGucian @id,@isgucian output
  if(@isgucian='1') 
  update GUCianProgressReport
  set state=@state
  where sid=@id and no=@progressReportNo
  else
  
  update NonGUCianProgressReport
  set state=@state
  where sid=@id and no=@progressReportNo
----------------------------------------6G-------------

go
create proc ViewEvalProgressReport 
@thesisSerialNo int, 
@progressReportNo int
as
select evaluation
from NonGUCianProgressReport
where NonGUCianProgressReport.no = @progressReportNo and serialNumber = @thesisSerialNo
union
select evaluation
from GUCianProgressReport
where GUCianProgressReport.no = @progressReportNo and serialNumber = @thesisSerialNo


----------------------------------------6H-------------

go
create proc addPublication 
@title varchar(50), 
@pubDate datetime,
@host varchar(50), 
@place varchar(50),
@accepted bit
as
insert into Publication values (@title, @pubDate, @place, @accepted, @host)


----------------------------------------6I-------------

go
create proc linkPubThesis 
@PubID int,
@thesisSerialNo int
as
insert into ThesisHasPublication values (@thesisSerialNo, @PubID);

-----------------------------------------------insertions


insert into PostGradUser values('1', 'swefwef');
insert into PostGradUser values('2', 'asdafefwwsd');
insert into PostGradUser values('3', 'wfeasdasd');
insert into PostGradUser values('4', 'gfdsgasdasd');
insert into PostGradUser values('5', 'dsfasdasd');
insert into PostGradUser values('6', 'sghasdasd');
insert into PostGradUser values('7', '5geasdasd');
insert into PostGradUser values('8', 'aerysdasd');
insert into PostGradUser values('9', 'ge45gadsasd');
insert into PostGradUser values('10', 'asdeasderht');
insert into PostGradUser values('11', 'serjyredfasf');
insert into PostGradUser values('12', 's435dfw');
insert into PostGradUser values('13', 'srthdav');
insert into PostGradUser values('14', 'rerfsadf');
insert into PostGradUser values('15', 'asdfgfsadf');
insert into PostGradUser values('16', 'asvdsadf');
insert into PostGradUser values('17', 'srthdav');
insert into PostGradUser values('18', 'rerfsadf');
insert into PostGradUser values('19', 'asdfgfsadf');
insert into PostGradUser values('20', 'asvdsadf');
insert into PostGradUser values('21', 'asdfgfsadf');
insert into PostGradUser values('22', 'asvdsadf');
insert into PostGradUser values('23', 'asvdsadf');
insert into PostGradUser values('24', 'asvdsadf');
insert into PostGradUser values('25', 'asvdsadf');
insert into PostGradUser values('26', 'assdfvsddsadf');

insert into GucianStudent values(2, 'a', 'a', 'master', 'MET', 'villa 98', 3276, 2.12);
insert into GucianStudent values(3, 'b', 'a', 'master', 'MET', 'villa 78', 1263, 3.72);
insert into GucianStudent values(4, 'c', 'a', 'master', 'MET', 'villa 48', 9823, 1.12);
insert into GucianStudent values(5, 'd', 'a', 'phd', 'MET', 'villa 38', 1267, 3.43);
insert into GucianStudent values(6, 'e', 'a', 'phd', 'MET', 'villa 238', 8721, 2.22);
insert into GucianStudent values(7, 'f', 'a', 'phd', 'MET', 'villa 238', 6318, 2.56);
insert into GucianStudent values(8, 'g', 'a', 'master', 'MET', 'villa 18', 2379, 1.67);
insert into GucianStudent values(9, 'h', 'a', 'master', 'MET', 'villa 23', 1263, 2.80);
insert into GucianStudent values(10, 'i', 'a', 'master', 'MET', 'villa 76', 2378, 3.9);
insert into NonGucianStudent values(11, 'j' ,'a', 'master', 'MET', 'villa 98', 2.12);
insert into NonGucianStudent values(12, 'k', 'a', 'master', 'MET', 'villa 78', 3.72);
insert into NonGucianStudent values(13, 'l', 'a', 'phd', 'MET', 'villa 38',  3.43);
insert into NonGucianStudent values(14, 'm', 'a', 'phd', 'MET', 'villa 238',  2.56);
insert into NonGucianStudent values(15, 'n', 'a', 'phd', 'MET', 'villa 238',  2.56);
insert into NonGucianStudent values(16, 'o','a' ,'master', 'MET', 'villa 23',  2.80);
insert into GUCStudentPhoneNumber values(2, '01023456885');
insert into GUCStudentPhoneNumber values(3, '01123454085');
insert into GUCStudentPhoneNumber values(7, '01242070085');
insert into GUCStudentPhoneNumber values(8, '01020234085');
insert into Admin values(1);
insert into NonGUCStudentPhoneNumber values(16, '01023456885');
insert into NonGUCStudentPhoneNumber values(14, '01123454085');
insert into NonGUCStudentPhoneNumber values(12, '01242070085');
insert into NonGUCStudentPhoneNumber values(11, '01020234085');


insert into Course values( 1000, 4, 'MATH01');
insert into Course values( 2000, 6, 'MATH02');
insert into Course values( 3000, 6, 'MATH03');
insert into Course values( 1500, 5, 'CSNE01');
insert into Course values( 1250, 2, 'CSNE02');
insert into Course values( 1300, 4, 'CSNE03');
insert into Course values( 3300, 2, 'MATH04');
insert into Course values( 2000, 4, 'MATH05');
insert into Course values( 7000, 3, 'CSNE04');
insert into Supervisor values(17, 'ahmed', 'MET');
insert into Supervisor values(18, 'Salma', 'BI');
insert into Supervisor values(19, 'Jana', 'MET');
insert into Supervisor values(20, 'sami', 'BI');
insert into Supervisor values(21, 'abdallah', 'BI');
insert into Supervisor values(22, 'soso', 'MET');


-----------------------------------

INSERT INTO Publication VALUES ('Economy of the Poor', '01/02/2022', 'Hall 5', '1', 'AHMED')
INSERT INTO Publication VALUES ('Economy of the Rich', '06/07/2022', 'Hall 4', 0, 'RANA')
INSERT INTO Publication VALUES ('Machine Learning', '05/12/2022', 'Hall 2', 1, 'SAMI')


insert into Payment values(30000,1,5)
insert into Payment values(60000,2,10)
insert into Payment values(90000,3,15)
insert into Payment values(120000,4,20)
insert into Payment values(150000,5,25)
insert into Payment values(180000,6,30)
insert into Payment values(210000,7,35)
insert into Payment values(240000,8,40)


insert into thesis values('BI','Masters','Stocks','2012-03-07','2013-01-15','2014-02-27',11,1,1)
insert into thesis values('Management','Bachelor','PR','2012-02-09','2013-01-21','2014-02-06',22,2,2)
insert into thesis values('Applied Arts','PHD','Photography','2012-02-21','2013-02-03','2014-02-21',33,3,3)
insert into thesis values('Pharmacy','Masters','chemistry','2012-01-18','2013-02-16','2014-02-09',44,4,4)
insert into thesis values('Law','PHD','books','2012-02-18','2013-01-24','2014-02-16',55,5,5)
insert into thesis values('Computer Science','Masters','ML','2012-01-21','2013-01-29','2014-02-11',66,6,6)
insert into thesis values('Medicine','Masters','cancer','2012-01-24','2013-01-23','2014-01-31',77,7,7)
insert into thesis values('Engineering','Bachelor','Plane','2012-02-09','2013-01-29','2014-01-20',88,8,8)



insert into Defense values(1, '2022-03-11', 'Hall 4', 3.21);
insert into Defense values(2, '2022-11-21', 'Hall 12', 3.21);
insert into Defense values(3, '2022-06-21', 'Hall 3', 3.21);
insert into Defense values(4, '2022-04-12', 'Hall 12', 3.21);
insert into Defense values(5, '2022-03-14', 'Hall 23', 3.21);
insert into Defense values(6, '2022-12-27', 'Hall 7', 3.21);
insert into Defense values(7, '2022-05-01', 'Hall 11', 3.21);
insert into Defense values(8, '2022-03-06', 'Hall 10', 3.21);




insert into GUCianProgressReport values(2, '11-11-2022', 4, 1, 1, 17);
insert into GUCianProgressReport values(3, '11-12-2022', 3, 2, 2, 18);
insert into GUCianProgressReport values(4, '05-05-2022', 2, 1, 3, 19);
insert into GUCianProgressReport values(5, '11-09-2022', 6, 2, 4, 20);


insert into NonGUCianProgressReport values(11, '11-11-2022', 4, 1, 6, 17);
insert into NonGUCianProgressReport values(12, '11-12-2022', 3, 2, 7, 18);
insert into NonGUCianProgressReport values(15, '05-05-2022', 2, 1, 8, 19);
insert into NonGUCianProgressReport values(16, '11-09-2022', 6, 2, 5, 20);



insert into Installment values('11-09-2022', 500, 1, 0);
insert into Installment values('12-09-2022', 600, 2, 1);
insert into Installment values('11-08-2022', 800, 3, 1);
insert into Installment values('02-11-2022', 450, 4, 1);
insert into Installment values('01-10-2022', 500, 5, 0);


insert into GUCianStudentRegisterThesis values(2,17,4)
insert into GUCianStudentRegisterThesis values(3,18,4)
insert into GUCianStudentRegisterThesis values(4,19,6)
insert into GUCianStudentRegisterThesis values(5,20,1)
insert into GUCianStudentRegisterThesis values(6,21,6)
insert into GUCianStudentRegisterThesis values(7,22,6)

insert into NonGUCianStudentRegisterThesis values(11,17,3)
insert into NonGUCianStudentRegisterThesis values(12,18,6)
insert into NonGUCianStudentRegisterThesis values(13,19,5)
insert into NonGUCianStudentRegisterThesis values(14,20,1)
insert into NonGUCianStudentRegisterThesis values(15,21,1)
insert into NonGUCianStudentRegisterThesis values(16,22,4)


insert into NonGucianStudentTakeCourse values(11,1,66)
insert into NonGucianStudentTakeCourse values(12,2,72)
insert into NonGucianStudentTakeCourse values(13,3,78)
insert into NonGucianStudentTakeCourse values(14,4,84)
insert into NonGucianStudentTakeCourse values(15,5,90)
insert into NonGucianStudentTakeCourse values(16,6,96)

insert into ThesisHasPublication values(5,3)
insert into ThesisHasPublication values(6,2)
insert into ThesisHasPublication values(7,2)

insert into Examiner values(23,'Ahmed', 'Computer Science',0)
insert into Examiner values(24,'Menna', 'Social Science', 1)
insert into Examiner values(25,'Jana', 'Economics', 1)
insert into Examiner values(26,'Ahmed', 'Computer Science', 1)

insert into ExaminerEvaluateDefense values('2022-03-11', 1, 23, 'Amazing');
insert into ExaminerEvaluateDefense values('2022-11-21', 2,  24, 'So bad');
insert into ExaminerEvaluateDefense values('2022-06-21',  3, 25, 'Good');
insert into ExaminerEvaluateDefense values( '2022-04-12', 4,  26, 'Outstanding');

-------------------------------------------------------------------------------executations

exec StudentRegister 'abdullah','sameh','abdosam','met',1,'abdullahsameh@gmail.com','ts3een villa 46'

exec SupervisorRegister 'alaa','ahmed','a2wcda','met','alaahmed@gmail.com'

declare @accept bit 
exec userLogin 1,'swefwef',@accept output
print @accept

exec addMobile 4,'0123212121'

exec AdminListSup


exec AdminViewSupervisorProfile 17

exec AdminViewAllTheses

declare @num int
exec AdminViewOnGoingTheses @num output
print @num

exec AdminViewStudentThesisBySupervisor




exec AdminListNonGucianCourse 1

exec AdminUpdateExtension 2

exec AdminIssueThesisPayment 1,34566,3,30

exec AdminViewStudentProfile 2

exec AdminIssueInstallPayment 6,'1/1/2019'

exec AdminListAcceptPublication
 
exec AddCourse '234',6,32000

exec linkCourseStudent 2,11

exec addStudentCourseGrade 2,11,98

exec ViewExamSupDefense '1-1-2010'

exec EvaluateProgressReport 17,1,1,3 

exec ViewSupStudentsYear 17


exec AddDefenseGrade 1, '11-11-2020',2

exec AddCommentsGrade 2, '11-11-2022', 'amazing'

exec viewMyProfile 4

exec editMyProfile 3, 'ahmed', 'sami', 'asdsadf', 'asfd@live.com', 'villa 98', 'type'

exec addUndergradID 3, 76723

exec ViewCoursesGrades 15

exec ViewEvalProgressReport 3,3


exec addPublication 'asdf','11-11-2022', 'asdf','asdfsdf',0

exec linkPubThesis 1,2

exec AddDefenseGrade 1, '11-11-2020',2

exec AddCommentsGrade 2, '11-11-2022', 'amazing'

exec ViewThesisPaymentsInstall 15
exec ViewUpcomingInstallments 12
exec ViewCoursePaymentsInstall 16

