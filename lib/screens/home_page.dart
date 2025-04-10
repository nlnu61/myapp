import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

// HomePage widget that displays the daily planner interface.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore db =
      FirebaseFirestore.instance; //new firestore instance
  final TextEditingController nameController =
      TextEditingController(); //captures textform input
  final List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  //Fetches tasks from the firestore and update local task list
  Future<void> fetchTasks() async {
    final snapshot = await db.collection('tasks').orderBy('timestamp').get();

    // Update the local task list with the fetched tasks.
    setState(() {
      tasks.clear();
      tasks.addAll(
        snapshot.docs.map(
          (doc) => {
            'id': doc.id,
            'name': doc.get('name'),
            'completed': doc.get('completed') ?? false,
          },
        ),
      );
    });
  }

  //Function that adds new tasks to local state & firestore database
  Future<void> addTask() async {
    final taskName = nameController.text.trim();

    // Check if the task name is not empty.
    if (taskName.isNotEmpty) {
      final newTask = {
        'name': taskName,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      //docRef gives us the insertion id of the task from the database
      final docRef = await db.collection('tasks').add(newTask);

      //Adding tasks locally
      setState(() {
        tasks.add({'id': docRef.id, ...newTask});
      });
      // Clear the text field for the next task
      nameController.clear();
    }
  }

  //Updates the completion status of the task in Firestore & locally
  Future<void> updateTask(int index, bool completed) async {
    // Get the task to be updated.
    final task = tasks[index];
    // Update the completion status of the task in Firestore.
    await db.collection('tasks').doc(task['id']).update({
      'completed': completed,
    });

    // Update the completion status of the task locally.
    setState(() {
      tasks[index]['completed'] = completed;
    });
  }

  //Delete the task locally & in the Firestore
  Future<void> removeTasks(int index) async {
    final task = tasks[index];

    // Delete the task from Firestore.
    await db.collection('tasks').doc(task['id']).delete();

    // Remove the task from the local task list.
    setState(() {
      tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          // Display the app logo
          children: [
            Expanded(child: Image.asset('assets/rdplogo.png', height: 80)),
            // Display the app title.
            const Text(
              'Daily Planner',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                // Display the calendar.
                children: [
                  TableCalendar(
                    calendarFormat: CalendarFormat.month,
                    focusedDay: DateTime.now(),
                    firstDay: DateTime(2025),
                    lastDay: DateTime(2026),
                  ),
                  // Display the task list.
                  buildTaskList(tasks, removeTasks, updateTask),
                ],
              ),
            ),
          ),
          // Display the add task section.
          buildAddTaskSection(nameController, addTask),
        ],
      ),
      drawer: Drawer(),
    );
  }
}

//Build the section for adding tasks
Widget buildAddTaskSection(nameController, addTask) {
  return Container(
    decoration: const BoxDecoration(color: Colors.white),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        // Expands the text field to fill the available space.
        children: [
          Expanded(
            child: Container(
              child: TextField(
                maxLength: 32,
                // Links the text field to the nameController.
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Add Task',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
          // Creates an elevated button to add tasks.
          ElevatedButton(
            onPressed: addTask, //Adds tasks when pressed
            child: Text('Add Task'),
          ),
        ],
      ),
    ),
  );
}

//Widget that displays the task item on the UI
Widget buildTaskList(tasks, removeTasks, updateTask) {
  return ListView.builder(
    shrinkWrap: true,
    // Disables scrolling of the list view.
    physics: const NeverScrollableScrollPhysics(),
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      final task = tasks[index];
      final isEven = index % 2 == 0;

      return Padding(
        padding: EdgeInsets.all(1.0),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: isEven ? Colors.blue : Colors.green,
          leading: Icon(
            task['completed'] ? Icons.check_circle : Icons.circle_outlined,
          ),
          // Displays the task's name.
          title: Text(
            task['name'],
            style: TextStyle(
              decoration: task['completed'] ? TextDecoration.lineThrough : null,
              fontSize: 22,
            ),
          ),
          // Displays a checkbox and a delete button.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: task['completed'],
                onChanged: (value) => updateTask(index, value!),
              ),
              // Creates an icon button to delete the task.
              IconButton(
                icon: Icon(Icons.delete),
                // Calls the removeTasks function when the button is pressed.
                onPressed: () => removeTasks(index),
              ),
            ],
          ),
        ),
      );
    },
  );
}
