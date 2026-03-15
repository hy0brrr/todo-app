import React, { useState, useEffect, useRef } from 'react';
import { Check, Star, Calendar, Plus, Settings, CheckSquare, Trash2, GripVertical, X } from 'lucide-react';

// --- Types ---
type Partition = {
  id: string;
  name: string;
  color: string;
  height: number;
};

type Task = {
  id: string;
  partitionId: string;
  name: string;
  isCompleted: boolean;
  isStarred: boolean;
  dueDate: string | null;
  createdAt: number;
  completedAt: number | null;
};

// --- Constants ---
const COLORS = [
  { name: 'Blue', value: 'bg-blue-500' },
  { name: 'Green', value: 'bg-green-500' },
  { name: 'Red', value: 'bg-red-500' },
  { name: 'Yellow', value: 'bg-yellow-500' },
  { name: 'Purple', value: 'bg-purple-500' },
  { name: 'Orange', value: 'bg-orange-500' },
];

const INITIAL_PARTITIONS: Partition[] = [
  { id: 'p1', name: 'Work', color: 'bg-blue-500', height: 200 },
  { id: 'p2', name: 'Life', color: 'bg-green-500', height: 200 },
];

const INITIAL_TASKS: Task[] = [
  { id: 't1', partitionId: 'p1', name: 'Q3 Product PRD', isCompleted: false, isStarred: true, dueDate: null, createdAt: Date.now() - 10000, completedAt: null },
  { id: 't2', partitionId: 'p1', name: 'Update roadmap', isCompleted: false, isStarred: false, dueDate: new Date().toISOString().split('T')[0], createdAt: Date.now() - 5000, completedAt: null },
  { id: 't3', partitionId: 'p1', name: 'Sync with design', isCompleted: false, isStarred: false, dueDate: null, createdAt: Date.now() - 2000, completedAt: null },
  { id: 't4', partitionId: 'p2', name: 'Buy groceries', isCompleted: false, isStarred: true, dueDate: null, createdAt: Date.now() - 8000, completedAt: null },
  { id: 't5', partitionId: 'p2', name: 'Pick up laundry', isCompleted: false, isStarred: false, dueDate: null, createdAt: Date.now() - 4000, completedAt: null },
  { id: 't6', partitionId: 'p1', name: 'Write weekly report', isCompleted: true, isStarred: false, dueDate: null, createdAt: Date.now() - 20000, completedAt: Date.now() - 1000 },
  { id: 't7', partitionId: 'p2', name: 'Book flight tickets', isCompleted: true, isStarred: false, dueDate: null, createdAt: Date.now() - 25000, completedAt: Date.now() - 500 },
];

// --- Helpers ---
const isOverdue = (dateStr: string | null) => {
  if (!dateStr) return false;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const [year, month, day] = dateStr.split('-').map(Number);
  const dueDate = new Date(year, month - 1, day);
  return dueDate.getTime() <= today.getTime();
};

const formatDueDate = (dateStr: string | null) => {
  if (!dateStr) return '';
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const [year, month, day] = dateStr.split('-').map(Number);
  const dueDate = new Date(year, month - 1, day);
  const diffTime = dueDate.getTime() - today.getTime();
  const diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));
  
  if (diffDays === 0) return 'Due Today';
  if (diffDays === 1) return 'Due Tomorrow';
  if (diffDays === -1) return 'Due Yesterday';
  
  return `Due ${dueDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}`;
};

// --- Components ---

const TaskItem: React.FC<{ 
  task: Task, 
  onToggleComplete: (id: string) => void, 
  onToggleStar: (id: string) => void, 
  onSetDueDate: (id: string, date: string) => void 
}> = ({ 
  task, 
  onToggleComplete, 
  onToggleStar, 
  onSetDueDate 
}) => {
  return (
    <div className="group flex items-center gap-2 px-2 py-1.5 hover:bg-black/5 dark:hover:bg-white/5 rounded-md mx-2 transition-colors">
      <button 
        onClick={() => onToggleComplete(task.id)} 
        className={`flex-shrink-0 w-3.5 h-3.5 rounded-full border flex items-center justify-center transition-colors ${
          task.isCompleted 
            ? 'bg-gray-400 border-gray-400 dark:bg-gray-500 dark:border-gray-500' 
            : 'border-gray-400 dark:border-gray-500 hover:border-blue-500'
        }`}
      >
        {task.isCompleted && <Check size={10} className="text-white" strokeWidth={3} />}
      </button>
      
      <span className={`flex-1 text-[13px] truncate ${task.isCompleted ? 'text-gray-400 dark:text-gray-500 line-through' : ''}`}>
        {task.name}
      </span>
      
      {!task.isCompleted ? (
        <div className="flex items-center gap-1.5 relative">
          <div className="relative flex items-center justify-end min-w-[20px] h-5">
            {task.dueDate && (
              <span className={`text-[10px] whitespace-nowrap group-hover:opacity-0 transition-opacity ${isOverdue(task.dueDate) ? 'text-red-500 font-medium' : 'text-gray-400 dark:text-gray-500'}`}>
                {formatDueDate(task.dueDate)}
              </span>
            )}
            <div className="absolute right-0 flex items-center justify-center w-5 h-5 opacity-0 group-hover:opacity-100 transition-opacity">
              <Calendar size={12} className="text-gray-400 hover:text-blue-500" />
              <input 
                type="date" 
                className="absolute inset-0 w-full h-full opacity-0 cursor-pointer" 
                value={task.dueDate || ''}
                onChange={(e) => onSetDueDate(task.id, e.target.value)}
                title="Set due date"
              />
            </div>
          </div>
          <button onClick={() => onToggleStar(task.id)} className="flex-shrink-0 focus:outline-none">
            <Star 
              size={13} 
              className={`transition-all ${task.isStarred ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300 dark:text-gray-600 opacity-0 group-hover:opacity-100 hover:text-yellow-400 dark:hover:text-yellow-400'}`} 
            />
          </button>
        </div>
      ) : (
        task.isStarred && (
          <div className="flex items-center gap-1.5 relative">
            <div className="flex-shrink-0">
              <Star 
                size={13} 
                className="text-gray-400 dark:text-gray-500 fill-gray-400 dark:fill-gray-500" 
              />
            </div>
          </div>
        )
      )}
    </div>
  );
};

const PartitionView: React.FC<{
  partition: Partition,
  tasks: Task[],
  isEditing: boolean,
  onAddTask: (partitionId: string, name: string) => void,
  onToggleComplete: (id: string) => void,
  onToggleStar: (id: string) => void,
  onSetDueDate: (id: string, date: string) => void,
  onStartEdit: () => void,
  onSaveEdit: (name: string, color: string) => void
}> = ({ 
  partition, 
  tasks, 
  isEditing,
  onAddTask, 
  onToggleComplete, 
  onToggleStar, 
  onSetDueDate, 
  onStartEdit,
  onSaveEdit
}) => {
  const [newTaskName, setNewTaskName] = useState('');
  const [editName, setEditName] = useState(partition.name);
  const [editColor, setEditColor] = useState(partition.color);

  useEffect(() => {
    if (isEditing) {
      setEditName(partition.name);
      setEditColor(partition.color);
    }
  }, [isEditing, partition]);
  
  const sortedTasks = tasks
    .filter(t => t.partitionId === partition.id && !t.isCompleted)
    .sort((a, b) => {
      if (a.isStarred && !b.isStarred) return -1;
      if (!a.isStarred && b.isStarred) return 1;
      return b.createdAt - a.createdAt; // Newest first
    });

  const handleAddTask = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTaskName.trim()) return;
    onAddTask(partition.id, newTaskName.trim());
    setNewTaskName('');
  };

  const handleSave = () => {
    onSaveEdit(editName.trim() || 'Untitled', editColor);
  };

  return (
    <div style={{ height: partition.height }} className="flex flex-col flex-shrink-0 bg-white dark:bg-[#252525] rounded-xl shadow-md border border-black/5 dark:border-white/5 overflow-hidden">
      {isEditing ? (
        <div className="flex flex-col gap-2 px-3 py-2 bg-white/50 dark:bg-black/20 border-b border-black/5 dark:border-white/5">
          <div className="flex items-center gap-2">
            <input
              autoFocus
              type="text"
              value={editName}
              onChange={e => setEditName(e.target.value)}
              onKeyDown={e => { if (e.key === 'Enter') handleSave(); }}
              className="flex-1 bg-transparent text-[12px] font-bold text-gray-700 dark:text-gray-200 outline-none border-b border-blue-500 focus:border-blue-600"
              placeholder="Partition Name"
            />
            <button onClick={handleSave} className="text-blue-500 hover:text-blue-600">
              <Check size={14} />
            </button>
          </div>
          <div className="flex gap-1.5 mt-1">
            {COLORS.map(c => (
              <button
                key={c.value}
                onClick={() => setEditColor(c.value)}
                className={`w-3.5 h-3.5 rounded-full ${c.value} ${editColor === c.value ? 'ring-1 ring-offset-1 ring-blue-500 dark:ring-offset-[#252525]' : ''}`}
                title={c.name}
              />
            ))}
          </div>
        </div>
      ) : (
        <div className="flex items-center justify-between px-3 py-2 group">
          <div className="flex items-center gap-2">
            <div className={`w-2 h-2 rounded-full ${partition.color} shadow-sm`} />
            <span className="text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">{partition.name}</span>
          </div>
          <button 
            onClick={onStartEdit} 
            className="opacity-0 group-hover:opacity-100 text-gray-400 hover:text-blue-500 transition-opacity"
            title="Partition Settings"
          >
            <Settings size={12} />
          </button>
        </div>
      )}
      
      <div className="flex-1 min-h-0 overflow-y-auto pb-1 custom-scrollbar">
        {sortedTasks.map(task => (
          <TaskItem 
            key={task.id} 
            task={task} 
            onToggleComplete={onToggleComplete}
            onToggleStar={onToggleStar}
            onSetDueDate={onSetDueDate}
          />
        ))}
        {sortedTasks.length === 0 && (
          <div className="px-4 py-2 text-[12px] text-gray-400 dark:text-gray-600 italic">
            No tasks yet.
          </div>
        )}
      </div>
      
      <div className="px-3 py-1.5 border-t border-black/5 dark:border-white/5">
        <form onSubmit={handleAddTask} className="flex items-center gap-2">
          <Plus size={12} className="text-gray-400" />
          <input 
            type="text" 
            placeholder={`Add task to ${partition.name}...`}
            className="w-full bg-transparent text-[13px] outline-none placeholder-gray-400 dark:placeholder-gray-500"
            value={newTaskName}
            onChange={e => setNewTaskName(e.target.value)}
          />
        </form>
      </div>
    </div>
  );
};

const CompletedPartition: React.FC<{ tasks: Task[], onToggleComplete: (id: string) => void }> = ({ tasks, onToggleComplete }) => {
  const completedTasks = tasks
    .filter(t => t.isCompleted)
    .sort((a, b) => (b.completedAt || 0) - (a.completedAt || 0));

  return (
    <div className="flex-1 min-h-0 flex flex-col overflow-hidden bg-white dark:bg-[#252525] rounded-xl shadow-md border border-black/5 dark:border-white/5">
      <div className="flex items-center gap-2 px-3 py-2">
        <div className="w-2 h-2 rounded-full bg-gray-400 dark:bg-gray-600 shadow-sm" />
        <span className="text-[11px] font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Completed</span>
      </div>
      <div className="flex-1 min-h-0 overflow-y-auto pb-2 custom-scrollbar">
        {completedTasks.map(task => (
          <TaskItem 
            key={task.id} 
            task={task} 
            onToggleComplete={onToggleComplete}
            onToggleStar={() => {}}
            onSetDueDate={() => {}}
          />
        ))}
        {completedTasks.length === 0 && (
          <div className="px-4 py-2 text-[12px] text-gray-400 dark:text-gray-600 italic">
            No completed tasks.
          </div>
        )}
      </div>
    </div>
  );
};

const DragHandle: React.FC<{ partition: Partition, onDrag: (height: number) => void }> = ({ partition, onDrag }) => {
  return (
    <div className="relative h-3 w-full flex-shrink-0 z-10 group">
      <div 
        className="absolute inset-x-2 -top-0.5 -bottom-0.5 cursor-row-resize rounded-full transition-colors group-hover:bg-blue-500/20"
        onMouseDown={(e) => {
          e.preventDefault();
          const startY = e.clientY;
          const initialHeight = partition.height;
          
          const onMouseMove = (moveEvent: MouseEvent) => {
            const newHeight = Math.max(80, initialHeight + (moveEvent.clientY - startY));
            onDrag(newHeight);
          };
          
          const onMouseUp = () => {
            document.removeEventListener('mousemove', onMouseMove);
            document.removeEventListener('mouseup', onMouseUp);
            document.body.style.cursor = 'default';
          };
          
          document.body.style.cursor = 'row-resize';
          document.addEventListener('mousemove', onMouseMove);
          document.addEventListener('mouseup', onMouseUp);
        }}
      />
    </div>
  );
};

const ManagePartitionsModal: React.FC<{
  partitions: Partition[],
  onClose: () => void,
  onReorder: (newPartitions: Partition[]) => void,
  onDelete: (id: string) => void
}> = ({ partitions, onClose, onReorder, onDelete }) => {
  const [localPartitions, setLocalPartitions] = useState(partitions);
  const [draggedIndex, setDraggedIndex] = useState<number | null>(null);
  const [partitionToDelete, setPartitionToDelete] = useState<Partition | null>(null);

  useEffect(() => {
    setLocalPartitions(partitions);
  }, [partitions]);

  const handleDragStart = (e: React.DragEvent, index: number) => {
    setDraggedIndex(index);
    e.dataTransfer.effectAllowed = 'move';
  };

  const handleDragOver = (e: React.DragEvent, index: number) => {
    e.preventDefault();
    if (draggedIndex === null || draggedIndex === index) return;

    const newPartitions = [...localPartitions];
    const draggedItem = newPartitions[draggedIndex];
    newPartitions.splice(draggedIndex, 1);
    newPartitions.splice(index, 0, draggedItem);
    
    setLocalPartitions(newPartitions);
    setDraggedIndex(index);
  };

  const handleDragEnd = () => {
    setDraggedIndex(null);
  };

  const handleSave = () => {
    onReorder(localPartitions);
    onClose();
  };

  const confirmDelete = () => {
    if (partitionToDelete) {
      onDelete(partitionToDelete.id);
      setPartitionToDelete(null);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/20 backdrop-blur-sm flex items-center justify-center z-50">
      <div className="bg-white dark:bg-[#252525] rounded-xl shadow-2xl w-80 overflow-hidden border border-black/10 dark:border-white/10 flex flex-col max-h-[80vh]">
        <div className="px-4 py-3 border-b border-black/5 dark:border-white/5 flex justify-between items-center">
          <h3 className="text-[13px] font-semibold">Manage Partitions</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
            <X size={14} />
          </button>
        </div>
        
        <div className="p-2 overflow-y-auto flex-1 custom-scrollbar">
          {localPartitions.map((p, index) => (
            <div 
              key={p.id}
              draggable
              onDragStart={(e) => handleDragStart(e, index)}
              onDragOver={(e) => handleDragOver(e, index)}
              onDragEnd={handleDragEnd}
              className={`flex items-center justify-between px-3 py-2 rounded-lg mb-1 bg-black/5 dark:bg-white/5 border border-transparent ${draggedIndex === index ? 'opacity-50' : ''} hover:border-black/10 dark:hover:border-white/10 transition-colors`}
            >
              <div className="flex items-center gap-3">
                <div className="cursor-grab active:cursor-grabbing text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
                  <GripVertical size={14} />
                </div>
                <div className={`w-2.5 h-2.5 rounded-full ${p.color} shadow-sm`} />
                <span className="text-[13px] font-medium">{p.name || 'Untitled'}</span>
              </div>
              <button 
                onClick={() => setPartitionToDelete(p)}
                className="text-gray-400 hover:text-red-500 transition-colors p-1"
                title="Delete Partition"
              >
                <Trash2 size={14} />
              </button>
            </div>
          ))}
          {localPartitions.length === 0 && (
            <div className="text-center py-4 text-[12px] text-gray-400">No partitions</div>
          )}
        </div>

        <div className="p-3 border-t border-black/5 dark:border-white/5 bg-black/5 dark:bg-white/5 flex justify-end gap-2">
          <button onClick={onClose} className="px-4 py-1.5 text-[12px] rounded-md hover:bg-black/5 dark:hover:bg-white/5 transition-colors">Cancel</button>
          <button onClick={handleSave} className="px-4 py-1.5 text-[12px] font-medium bg-blue-500 text-white rounded-md hover:bg-blue-600 transition-colors">Save Order</button>
        </div>
      </div>

      {/* Delete Confirmation Modal */}
      {partitionToDelete && (
        <div className="fixed inset-0 bg-black/20 backdrop-blur-sm flex items-center justify-center z-[60]">
          <div className="bg-white dark:bg-[#252525] rounded-xl shadow-2xl w-72 overflow-hidden border border-black/10 dark:border-white/10">
            <div className="p-4">
              <h3 className="text-[14px] font-semibold mb-2">Delete Partition?</h3>
              <p className="text-[12px] text-gray-500 dark:text-gray-400">
                Are you sure you want to delete "{partitionToDelete.name || 'Untitled'}"? All tasks inside this partition will also be deleted. This action cannot be undone.
              </p>
            </div>
            <div className="flex border-t border-black/5 dark:border-white/5 bg-black/5 dark:bg-white/5">
              <button onClick={() => setPartitionToDelete(null)} className="flex-1 py-2 text-[13px] hover:bg-black/5 dark:hover:bg-white/5 transition-colors">Cancel</button>
              <div className="w-[1px] bg-black/5 dark:bg-white/5" />
              <button onClick={confirmDelete} className="flex-1 py-2 text-[13px] font-semibold text-red-500 hover:bg-red-500/10 transition-colors">Delete</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// --- Main App ---
export default function App() {
  const [sidebarWidth, setSidebarWidth] = useState(320);
  const [editingPartitionId, setEditingPartitionId] = useState<string | null>(null);
  const [showManagePartitions, setShowManagePartitions] = useState(false);
  const [partitions, setPartitions] = useState<Partition[]>(INITIAL_PARTITIONS);
  const [tasks, setTasks] = useState<Task[]>(INITIAL_TASKS);

  // --- Actions ---
  const addTask = (partitionId: string, name: string) => {
    const newTask: Task = {
      id: Math.random().toString(36).substr(2, 9),
      partitionId,
      name,
      isCompleted: false,
      isStarred: false,
      dueDate: null,
      createdAt: Date.now(),
      completedAt: null
    };
    setTasks([newTask, ...tasks]);
  };

  const toggleComplete = (taskId: string) => {
    setTasks(tasks.map(t => {
      if (t.id === taskId) {
        const isCompleted = !t.isCompleted;
        return { ...t, isCompleted, completedAt: isCompleted ? Date.now() : null };
      }
      return t;
    }));
  };

  const toggleStar = (taskId: string) => {
    setTasks(tasks.map(t => t.id === taskId ? { ...t, isStarred: !t.isStarred } : t));
  };

  const setDueDate = (taskId: string, dateStr: string) => {
    setTasks(tasks.map(t => t.id === taskId ? { ...t, dueDate: dateStr } : t));
  };

  const handleNewPartition = () => {
    const newId = Math.random().toString(36).substr(2, 9);
    const newPartition: Partition = {
      id: newId,
      name: '',
      color: COLORS[0].value,
      height: 200
    };
    setPartitions([newPartition, ...partitions]);
    setEditingPartitionId(newId);
  };

  const savePartitionEdit = (id: string, name: string, color: string) => {
    setPartitions(partitions.map(p => p.id === id ? { ...p, name, color } : p));
    setEditingPartitionId(null);
  };

  const deletePartition = (id: string) => {
    setPartitions(partitions.filter(p => p.id !== id));
    setTasks(tasks.filter(t => t.partitionId !== id));
  };

  const updatePartitionHeight = (id: string, newHeight: number) => {
    setPartitions(partitions.map(p => p.id === id ? { ...p, height: newHeight } : p));
  };

  return (
    <div className="h-screen w-full overflow-hidden flex flex-col bg-gradient-to-br from-[#0f172a] via-[#1e1b4b] to-[#312e81] text-[#1d1d1f] dark:text-[#f5f5f7] font-sans selection:bg-blue-200 dark:selection:bg-blue-900">
      {/* macOS Global Menu Bar */}
      <div className="h-7 w-full bg-white/10 dark:bg-black/20 backdrop-blur-md flex items-center justify-between px-4 text-[13px] text-white font-medium border-b border-white/10 z-50 select-none">
        <div className="flex items-center gap-4">
          <span className="font-bold text-lg leading-none mb-1"></span>
          <span className="font-bold flex items-center gap-1.5">
            <CheckSquare size={14} className="text-blue-400" />
            Todo
          </span>
          
          <div className="relative group">
            <button className="hover:bg-white/20 px-2 py-0.5 rounded transition-colors">Partition</button>
            <div className="absolute top-full left-0 pt-1 hidden group-hover:block z-[100]">
              <div className="w-48 bg-white/95 dark:bg-[#252525]/95 backdrop-blur-xl shadow-xl rounded-lg border border-black/10 dark:border-white/10 py-1 text-black dark:text-white">
                <button 
                  className="w-full text-left px-4 py-1.5 text-[13px] hover:bg-blue-500 hover:text-white transition-colors flex items-center justify-between"
                  onClick={handleNewPartition}
                >
                  New Partition...
                  <span className="text-gray-400 text-[10px]">⌘N</span>
                </button>
                <div className="h-[1px] bg-black/10 dark:bg-white/10 my-1" />
                <button 
                  className="w-full text-left px-4 py-1.5 text-[13px] hover:bg-blue-500 hover:text-white transition-colors flex items-center justify-between"
                  onClick={() => setShowManagePartitions(true)}
                >
                  Manage Partitions...
                </button>
              </div>
            </div>
          </div>
        </div>
        
        <div className="flex items-center gap-4 text-[12px]">
          <span>{new Date().toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' })}</span>
          <span>{new Date().toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })}</span>
        </div>
      </div>
      
      {/* Desktop Area */}
      <div className="flex-1 min-h-0 flex justify-end relative">
        {/* Sidebar App */}
        <div 
          style={{ width: sidebarWidth }}
          className="h-full flex flex-col relative"
        >
          {/* Sidebar Drag Handle */}
          <div 
            className="absolute left-0 top-0 bottom-0 w-1.5 -ml-[0.75px] cursor-col-resize hover:bg-blue-500/30 z-50 transition-colors"
            onMouseDown={(e) => {
              e.preventDefault();
              const startX = e.clientX;
              const initialWidth = sidebarWidth;
              const onMouseMove = (moveEvent: MouseEvent) => {
                const delta = startX - moveEvent.clientX;
                setSidebarWidth(Math.max(200, Math.min(600, initialWidth + delta)));
              };
              const onMouseUp = () => {
                document.removeEventListener('mousemove', onMouseMove);
                document.removeEventListener('mouseup', onMouseUp);
                document.body.style.cursor = 'default';
              };
              document.body.style.cursor = 'col-resize';
              document.addEventListener('mousemove', onMouseMove);
              document.addEventListener('mouseup', onMouseUp);
            }}
          />
          
          {/* Partitions */}
          <div className="flex-1 min-h-0 flex flex-col overflow-hidden p-3">
            {partitions.map(p => (
              <React.Fragment key={p.id}>
                <PartitionView 
                  partition={p} 
                  tasks={tasks} 
                  isEditing={editingPartitionId === p.id}
                  onAddTask={addTask} 
                  onToggleComplete={toggleComplete}
                  onToggleStar={toggleStar}
                  onSetDueDate={setDueDate}
                  onStartEdit={() => setEditingPartitionId(p.id)}
                  onSaveEdit={(name, color) => savePartitionEdit(p.id, name, color)}
                />
                <DragHandle onDrag={(h) => updatePartitionHeight(p.id, h)} partition={p} />
              </React.Fragment>
            ))}
            <CompletedPartition tasks={tasks} onToggleComplete={toggleComplete} />
          </div>
        </div>
      </div>

      {/* Modals */}
      {showManagePartitions && (
        <ManagePartitionsModal
          partitions={partitions}
          onClose={() => setShowManagePartitions(false)}
          onReorder={setPartitions}
          onDelete={deletePartition}
        />
      )}
    </div>
  );
}
