# Quiz-plz
Create MCQ questions, arrange them into topics/categories and retrieve them as JSON

link to the deployed project on Heroku: https://quiz-plz.herokuapp.com

## Description
Quiz-plz is a server-side swift app written using Vapor framework, Fluent ORM (powered byPostgreSQL). It allows users to retrieve multiple-choice questions in the JSON form and use them where needed (e.g Mobile app).
Currently, only the admin can authneticate on the front-end and add new questions/categories of questions, however there is a public API which can be used to retrieve already existing data. 

### Public API
To use the public api, it would be beneficial to understand the main entities and relatinships between them. Below you can find the database schema:
![database-schema](/Public/images/database-schema.jpg "schema")


### Questions:
**Retrieving all possible Questions:**
```
/api/questions
```

**Retrieving a question data:**:
```
/api/questions/{questionID}
```

**Retrieving Categories that the particular question belongs to:**
```
/api/questions/{questionID}/categories
```

### Answers:
**Retrieving all possible Answers:**
```
/api/answers/
```

**Retrieving Answers for the particular question:**
```
/api/answers/{questionID}/
```
### Categories
**Retrieving all possible categories:**
```
/api/categories/
```

**Retrieving category data:** 
```
/api/categories/{categoryID}/
```

**Retrieving all questions that belong to particular category:** 
```
/api/categories/{categoryID}/questions/
```

### Users
**Retrieving users that have contributed to the Quiz-plz:**
```
/api/users/
```

**Retrieving questions that a particular user might have created and added to Quiz-plz:**
```
/api/users/{userID}/questions
```








